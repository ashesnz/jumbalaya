--[[ word_game/ui/boss_word_stack.lua - Bonus card stack (boss word rewards on stages 1-4 … 1-6) ]]

local placement_layout = require("word_game.ui.layout.placement")
local board_config = require("word_game.board.config")
local DissolveFX = require("app.effects.dissolve_fx")
local deck = require("word_game.model.cards.deck")
local LetterPalette = require("word_game.config.letter_card_palette")
local round_config = require("word_game.config.round_config")

local M = {}

M.BONUS_POINTS = 10
M.LEFT_WINDOW_MARGIN = 0.14
M.STACK_Y_LIFT_PX = 20

local TRANSFORM_DISSOLVE_TIME = 0.7
local TRANSFORM_MATERIALIZE_TIME = 0.6
local TRANSFORM_TOTAL = TRANSFORM_DISSOLVE_TIME + TRANSFORM_MATERIALIZE_TIME + 0.1
local BURN_DISSOLVE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD, G.C.MUTED_GREY }
local BURN_MATERIALIZE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.WHITE }
local BACKDROP_FILL_ALPHA = 0.18
local BACKDROP_LINE_ALPHA = 0.28

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
	if round_config.is_bonus_stack_hand(set, hand_index) then
		if not stack_animating then
			M.sync_positions()
		end
		return
	end
	M.clear()
end

local function card_letter(card)
	return (card.ability and card.ability.letter)
		or (card.config and card.config.card and card.config.card.letter)
end

function M.apply_gold_bonus_face(card)
	local letter = card_letter(card)
	if not letter then return end
	local color = LetterPalette.BONUS_FACE_COLOR
	local front = deck.front(letter, color)
	if front and card.apply_face then
		deck.tag_card(card, letter, color)
		card:apply_face(front, false)
	end
	if card.bonus_card then
		card.dissolve = 0
		card.dissolve_wipe = 0
		card.dissolve_colours = nil
	end
end

--- Gold face + shimmer flag. Used when the dissolve rematerializes, before
--- the fly to the left gutter, so the card already looks like a bonus card.
function M.become_bonus_card(card)
	if not card or card.REMOVED then return end
	card.bonus_card = true
	card.boss_temp = nil
	card.placement_locked = nil
	card.pinned = nil
	if card.ability then
		card.ability.bonus = M.BONUS_POINTS
	end
	M.apply_gold_bonus_face(card)
end

local function reconcile_bonus_faces()
	for _, card in ipairs(stack_cards or {}) do
		if card and card.bonus_card and not card.REMOVED then
			M.apply_gold_bonus_face(card)
		end
	end
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

local function window_left_x()
	return -((G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0)
end

function M.stack_y_lift()
	local dim_ok, dim = pcall(require, "word_game.config.dimensions")
	local tile = G.TILESIZE or (dim_ok and dim.TILESIZE) or 20
	local scale = G.TILESCALE or (dim_ok and dim.TILESCALE) or 1
	local px_per_tile = tile * scale
	if px_per_tile <= 0 then
		px_per_tile = (dim_ok and dim.CANVAS_TILE_PX) or 73
	end
	return (M.STACK_Y_LIFT_PX or 20) / px_per_tile
end

function M.stack_layout()
	local timer = placement_layout.timeline_rect()
	local card_w = G.CARD_W or 1
	local card_h = G.CARD_H or 1.4
	local margin_x = M.LEFT_WINDOW_MARGIN
	local margin_y = math.max(0.10, card_h * 0.08)
	local lift = M.stack_y_lift()
	local x = window_left_x() + margin_x
	local y = timer.y + timer.h + margin_y - lift
	return {
		x = x,
		y = y,
		card_w = card_w,
		card_h = card_h,
		step_y = card_h * 0.5,
		clearance = math.max(0.45, card_w * 0.30),
		label_y = timer.y + timer.h + margin_y * 0.35 - lift,
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
			if card.area == G.hand and M.is_bonus_card(card) then
				M.return_card(card)
			elseif card.area == placement then
				-- Bonus cards placed in the puzzle row keep their slot layout.
			else
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
	reconcile_bonus_faces()
end

function M.promote_to_bonus(cards)
	stack_animating = false
	stack_cards = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			M.become_bonus_card(card)
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

local function run_gold_transform(card, on_complete)
	if not card or not DissolveFX or not DissolveFX.run then
		M.become_bonus_card(card)
		if on_complete then on_complete() end
		return
	end

	if card.states then
		card.states.visible = true
	end
	card.dissolve = 0
	card.dissolve_wipe = 0
	card.dissolve_colours = BURN_DISSOLVE_COLOURS

	if play_sfx then
		play_sfx("whoosh2", math.random() * 0.2 + 0.9, 0.5)
		play_sfx("crumple" .. math.random(1, 5), math.random() * 0.2 + 0.9, 0.5)
	end

	DissolveFX.run(card, {
		mode = "out",
		duration = TRANSFORM_DISSOLVE_TIME,
		wipe = 0,
		pulse = true,
		colours = BURN_DISSOLVE_COLOURS,
		fade = {
			delay = 0.7 * TRANSFORM_DISSOLVE_TIME,
			duration = 0.3 * TRANSFORM_DISSOLVE_TIME,
		},
		on_finish = function()
			-- Rematerialize as a gold shimmer bonus card, then fly to the gutter.
			M.become_bonus_card(card)
			card.dissolve = 1
			card.dissolve_wipe = 0
			card.dissolve_colours = BURN_MATERIALIZE_COLOURS
			DissolveFX.run(card, {
				mode = "in",
				duration = TRANSFORM_MATERIALIZE_TIME,
				wipe = 0,
				pulse = true,
				colours = BURN_MATERIALIZE_COLOURS,
				particle = { timer = 0.025, scale = 0.25, speed = 3, lifespan = 0.7 },
				on_finish = function()
					card.dissolve = 0
					card.dissolve_wipe = 0
					card.dissolve_colours = nil
					if on_complete then on_complete() end
				end,
			})
		end,
	})
end

local function fly_card_to_stack(queue_event, card, fly_index, card_delay)
	local sx, sy = card.T.x, card.T.y
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
			card.T.x = sx + (tx - sx) * e
			card.T.y = sy + (ty - sy) * e
			sync_card_transform(card)
			return u >= 1
		end,
	}))
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
		reconcile_bonus_faces()
		if opts.on_complete then opts.on_complete() end
	end

	local can_queue = queue_event and G.TIMELINE and G.TIMELINE.enqueue
	if not can_queue then
		for index, card in ipairs(cards) do
			M.become_bonus_card(card)
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
						run_gold_transform(fly_card, function()
							fly_card_to_stack(queue_event, fly_card, fly_index, card_delay)
						end)
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
		delay = initial_delay + ((#cards - 1) * stagger) + TRANSFORM_TOTAL + card_delay + hold,
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
		if G.placement_table and card.area == G.placement_table.area
			and G.placement_table.on_remove_card then
			G.placement_table:on_remove_card(card)
		end
		if card.area.remove_card then
			card.area:remove_card(card)
		end
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
	local count = math.max(1, #(stack_cards or {}))
	local pad_x = math.max(0.35, layout.card_w * 0.35)
	local pad_y = math.max(0.35, layout.card_h * 0.25)
	local top = layout.label_y - layout.card_h * 0.45
	local bottom = layout.y + (count - 1) * layout.step_y + layout.card_h + pad_y
	return x >= layout.x - pad_x
		and x <= layout.x + layout.card_w + pad_x
		and y >= top
		and y <= bottom
end

function M.drop_in_gutter(session, x, y)
	if M.point_in_stack(x, y) then return true end
	if not M.is_active() then return false end
	local area = session and session.area
	if not area or not area.T then return false end
	if x >= area.T.x then return false end
	local layout = M.stack_layout()
	local count = math.max(1, #(stack_cards or {}))
	local pad_y = math.max(0.35, layout.card_h * 0.25)
	local top = layout.label_y - layout.card_h * 0.55
	local bottom = layout.y + (count - 1) * layout.step_y + layout.card_h + pad_y
	local left = window_left_x()
	local right = layout.x + layout.card_w + math.max(0.35, layout.card_w * 0.35)
	return x >= left and x <= right and y >= top and y <= bottom
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

local function try_award_gutter_perk()
	if M.is_active() then return end
	local perk_stamp = WORD_GAME and WORD_GAME.PerkStamp
	if not perk_stamp then return end
	local perk_model = require("word_game.model.perk")
	local rolled = perk_model.roll_stamp_perk()
	if not rolled then return end
	if not perk_stamp.play(rolled) then
		perk_stamp.queue(rolled)
	end
	if spawn_attention then
		spawn_attention({
			text = "Perk earned!",
			scale = 0.55,
			hold = 1.1,
			align = "cm",
			colour = G.C and G.C.GOLD or { 1, 0.85, 0.2, 1 },
		})
	end
end

function M.consume_card(card)
	M.remove_card(card)
	if card.area and card.area.remove_card then
		card.area:remove_card(card)
	elseif card.remove_from_area then
		card:remove_from_area()
	end
	if card.start_dissolve then
		card:start_dissolve()
		try_award_gutter_perk()
		return
	end
	local deck = require("word_game.model.cards.deck")
	deck.destroy_card(card)
	try_award_gutter_perk()
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

function M.gutter_pixels(layout)
	layout = layout or M.stack_layout()
	local count = math.max(1, #(stack_cards or {}))
	local pad_x = math.max(0.35, layout.card_w * 0.35)
	local pad_y = math.max(0.35, layout.card_h * 0.25)
	local top = layout.label_y - layout.card_h * 0.45
	local bottom = layout.y + (count - 1) * layout.step_y + layout.card_h + pad_y
	local ts = G.TILESCALE * G.TILESIZE
	return layout.x * ts - pad_x * ts,
		top * ts,
		(layout.card_w + pad_x * 2) * ts,
		(bottom - top) * ts
end

function M.draw_shadow()
	if not stack_cards or #stack_cards == 0 then return end
	local layout = M.stack_layout()
	local px, py, pw, ph = M.gutter_pixels(layout)
	local radius = board_config.CORNER_RADIUS or 8

	love.graphics.setColor(0, 0, 0, BACKDROP_FILL_ALPHA)
	love.graphics.rectangle("fill", px, py, pw, ph, radius, radius)
	love.graphics.setColor(1, 1, 1, BACKDROP_LINE_ALPHA)
	love.graphics.setLineWidth(1.5)
	love.graphics.rectangle("line", px, py, pw, ph, radius, radius)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setLineWidth(1)
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
