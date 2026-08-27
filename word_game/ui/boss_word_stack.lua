--[[ word_game/ui/boss_word_stack.lua - Bonus card stack (boss word rewards on stage 1-4) ]]

local placement_layout = require("word_game.ui.layout.placement")

local M = {}

M.BONUS_POINTS = 10

local stack_cards
local stack_animating = false

function M.is_animating()
	return stack_animating
end

function M.is_bonus_card(card)
	return card and card.bonus_card
end

function M.detach(card)
	if not card then return end
	if G.placement_table and G.placement_table.on_remove_card then
		G.placement_table:on_remove_card(card)
	end
	if card.area and card.area.remove_card then
		card.area:remove_card(card)
	end
	if card.remove_from_area then
		card:remove_from_area()
	else
		card.area = nil
		card.parent = nil
	end
	if card.states and card.states.drag then
		card.states.drag.can = true
		card.states.drag.is = false
	end
	if card.states and card.states.collide then
		card.states.collide.can = true
	end
	if card.states then
		card.states.visible = true
	end
	if card.set_selected then
		card:set_selected(false)
	end
	if card.T then
		card.T.r = 0
	end
end

function M.is_active()
	return stack_cards ~= nil and #stack_cards > 0
end

function M.cards()
	return stack_cards
end

function M.set_cards(cards)
	M.stage_cards(cards)
end

function M.clear()
	stack_cards = nil
	stack_animating = false
end

function M.stage_cards(cards)
	stack_cards = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			stack_cards[#stack_cards + 1] = card
		end
	end
	stack_animating = #stack_cards > 0
end

function M.on_hand_start(set, hand_index)
	if set == 1 and hand_index == 4 then
		if not stack_animating then
			M.sync_positions()
		end
		return
	end
	M.clear()
end

local function gameplay_left_edge()
	local edge
	if G.hand and G.hand.T then
		edge = G.hand.T.x
	end
	local area = G.placement_table and G.placement_table.area
	if area and area.T then
		if edge then
			edge = math.min(edge, area.T.x)
		else
			edge = area.T.x
		end
	end
	if not edge then
		local felt = require("word_game.ui.layout.felt")
		edge = felt.play_column().x
	end
	return edge
end

function M.stack_layout()
	local timer = placement_layout.timeline_rect()
	local card_w = G.CARD_W or 1
	local card_h = G.CARD_H or 1.4
	local clearance = math.max(0.45, card_w * 0.30)
	local margin_y = math.max(0.10, card_h * 0.08)
	local room_x = (G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0
	local x = gameplay_left_edge() - clearance - card_w
	local screen_min = room_x - card_w * 2.5
	if x < screen_min then
		x = screen_min
	end
	return {
		x = x,
		y = timer.y + timer.h + margin_y,
		card_w = card_w,
		card_h = card_h,
		step_y = card_h * 0.5,
		clearance = clearance,
		label_y = timer.y + timer.h + margin_y * 0.35,
	}
end

function M.clears_gameplay_bounds()
	local layout = M.stack_layout()
	local left_edge = gameplay_left_edge()
	return layout.x + layout.card_w + layout.clearance <= left_edge + 0.02
end

function M.target_position(index)
	local layout = M.stack_layout()
	return layout.x, layout.y + (index - 1) * layout.step_y
end

function M.stack_index(card)
	if not stack_cards or not card then return nil end
	for i, c in ipairs(stack_cards) do
		if c == card then return i end
	end
	return nil
end

function M.contains(card)
	return M.stack_index(card) ~= nil
end

function M.sync_positions()
	if not stack_cards or stack_animating then return end
	local placement = G.placement_table and G.placement_table.area
	for i, card in ipairs(stack_cards) do
		if card and not card.REMOVED then
			local in_play = card.area and (card.area == placement or card.area == G.hand)
			if not in_play then
				if card.area then
					M.detach(card)
				end
				local tx, ty = M.target_position(i)
				if card.hard_set_T then
					card:hard_set_T(tx, ty, card.T.w, card.T.h)
				else
					card.T.x, card.T.y = tx, ty
				end
				if card.states and card.states.drag then
					card.states.drag.can = true
				end
				if card.states and card.states.collide then
					card.states.collide.can = true
				end
				if card.states then
					card.states.visible = true
				end
			end
		end
	end
end

function M.promote_to_bonus(cards)
	stack_animating = false
	stack_cards = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			card.bonus_card = true
			card.boss_temp = nil
			card.placement_locked = nil
			card.pinned = nil
			if card.ability then
				card.ability.bonus = M.BONUS_POINTS
			end
			stack_cards[#stack_cards + 1] = card
		end
	end
	M.sync_positions()
end

local function sync_card_transform(card)
	if card.VT and card.T then
		card.VT.x = card.T.x
		card.VT.y = card.T.y
		card.VT.w = card.T.w
		card.VT.h = card.T.h
		card.VT.r = card.T.r or 0
	end
end

local function snap_card_to(card, tx, ty)
	if card.hard_set_T then
		card:hard_set_T(tx, ty, card.T.w, card.T.h)
	else
		card.T.x, card.T.y = tx, ty
		sync_card_transform(card)
	end
end

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

function M.animate_cards_to_stack(queue_event, _easing_mod, opts)
	opts = opts or {}
	local cards = stack_cards or {}
	local card_delay = opts.card_delay or 0.45
	local stagger = opts.stagger or 0.07
	local hold = opts.hold or 0.3
	local initial_delay = opts.initial_delay or 0

	if #cards == 0 then
		if opts.on_complete then opts.on_complete() end
		return
	end

	stack_animating = true

	local function finish()
		stack_animating = false
		if opts.on_complete then opts.on_complete() end
	end

	local can_queue = queue_event and G.TIMELINE and G.TIMELINE.enqueue
	if not can_queue then
		for index, card in ipairs(cards) do
			local tx, ty = M.target_position(index)
			snap_card_to(card, tx, ty)
		end
		finish()
		return
	end

	queue_event(Tween({
		mode = "delayed",
		timer = "REAL",
		delay = initial_delay,
		blocking = true,
		func = function()
			for index, card in ipairs(cards) do
				local fly_card = card
				local fly_index = index
				queue_event(Tween({
					mode = "delayed",
					timer = "REAL",
					delay = (index - 1) * stagger,
					blockable = false,
					blocking = false,
					func = function()
						M.detach(fly_card)
						if fly_card.hard_set_T then
							fly_card:hard_set_T(fly_card.T.x, fly_card.T.y, fly_card.T.w, fly_card.T.h)
						else
							sync_card_transform(fly_card)
						end
						local sx, sy = fly_card.T.x, fly_card.T.y
						local tx, ty = M.target_position(fly_index)
						local started = (G.TIMERS and G.TIMERS.REAL) or 0
						if play_sfx then
							play_sfx("card_slide1", 0.88 + fly_index * 0.015, 0.55)
						end
						queue_event(Tween({
							mode = "window",
							timer = "REAL",
							delay = card_delay,
							blockable = false,
							blocking = false,
							func = function()
								local now = (G.TIMERS and G.TIMERS.REAL) or (started + card_delay)
								local u = card_delay > 0 and math.min(1, (now - started) / card_delay) or 1
								local e = smoothstep(u)
								fly_card.T.x = sx + (tx - sx) * e
								fly_card.T.y = sy + (ty - sy) * e
								sync_card_transform(fly_card)
								return u >= 1
							end,
						}))
						return true
					end,
				}))
			end
			return true
		end,
	}))

	queue_event(Tween({
		mode = "delayed",
		timer = "REAL",
		delay = initial_delay + ((#cards - 1) * stagger) + card_delay + hold,
		blocking = true,
		func = function()
			for index, card in ipairs(cards) do
				local tx, ty = M.target_position(index)
				snap_card_to(card, tx, ty)
			end
			finish()
			return true
		end,
	}))
end

function M.finalize_for_bonus_hand(wr)
	local j = wr and wr.jumble
	if j and j.boss_cards then
		local deck = require("word_game.model.cards.deck")
		for _, card in ipairs(j.boss_cards) do
			if card and not card.REMOVED and not card.bonus_card then
				deck.destroy_card(card)
			end
		end
		j.boss_cards = nil
	end
	if not stack_animating then
		M.sync_positions()
	end
end

function M.remove_card(card)
	if not stack_cards or not card then return end
	for i = #stack_cards, 1, -1 do
		if stack_cards[i] == card then
			table.remove(stack_cards, i)
			break
		end
	end
	if stack_cards and #stack_cards == 0 then
		stack_cards = nil
	else
		M.sync_positions()
	end
end

function M.return_card(card)
	if not card then return false end
	if not M.contains(card) then
		if card.bonus_card then
			stack_cards = stack_cards or {}
			stack_cards[#stack_cards + 1] = card
		else
			return false
		end
	end
	if card.area then
		if G.placement_table and card.area == G.placement_table.area then
			G.placement_table:on_remove_card(card)
		end
		card.area:remove_card(card)
	end
	if card.states and card.states.drag then
		card.states.drag.is = false
	end
	if card.set_selected then
		card:set_selected(false)
	end
	local index = M.stack_index(card) or 1
	local tx, ty = M.target_position(index)
	if card.hard_set_T then
		card:hard_set_T(tx, ty, card.T.w, card.T.h)
	end
	card.T.r = 0
	return true
end

function M.point_in_stack(x, y)
	if not M.is_active() then return false end
	local layout = M.stack_layout()
	local pad_x = layout.card_w * 0.15
	local pad_y = layout.card_h * 0.2
	local top = layout.label_y - layout.card_h * 0.35
	local bottom = layout.y + (#stack_cards - 1) * layout.step_y + layout.card_h + pad_y
	return x >= layout.x - pad_x
		and x <= layout.x + layout.card_w + pad_x
		and y >= top
		and y <= bottom
end

function M.bonus_points_for(used_cards)
	local total = 0
	for _, card in ipairs(used_cards or {}) do
		if M.is_bonus_card(card) then
			total = total + M.BONUS_POINTS
		end
	end
	return total
end

function M.consume_card(card)
	M.remove_card(card)
	local deck = require("word_game.model.cards.deck")
	deck.destroy_card(card)
end

local function draw_label(layout)
	if not M.is_active() then return end
	local font = G.FONTS and (G.FONTS.sm or G.FONTS.medium or G.FONTS.main)
	if not font then return end
	love.graphics.setFont(font)
	love.graphics.setColor(1, 0.92, 0.55, 0.95)
	local scale = 0.34
	local text = "Bonus Cards"
	local tw = font:getWidth(text) * scale
	love.graphics.print(text, layout.x + (layout.card_w - tw) * 0.5, layout.label_y, 0, scale, scale)
	love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_pass()
	if not stack_cards then return end
	local layout = M.stack_layout()
	if M.is_active() and not stack_animating then
		draw_label(layout)
	end
	local dragging = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	local focused = G.INPUT and G.INPUT.focused and G.INPUT.focused.target
	for _, card in ipairs(stack_cards) do
		if card and not card.REMOVED and not card.area
			and card ~= dragging and card ~= focused then
			love.graphics.push()
			card:translate_container()
			card:draw()
			love.graphics.pop()
		end
	end
end

return M
