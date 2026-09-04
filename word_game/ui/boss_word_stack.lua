--[[ word_game/ui/boss_word_stack.lua - Bonus card stack (boss word rewards on stages 1-4 … 1-6) ]]

local model = require("word_game.model.bonus_stack")
local gutter = require("word_game.board.bonus_gutter")
local placement_layout = require("word_game.ui.layout.placement")
local board_config = require("word_game.board.config")
local DissolveFX = require("app.effects.dissolve_fx")
local deck = require("word_game.model.cards.deck")
local LetterPalette = require("word_game.config.letter_card_palette")
local round_config = require("word_game.config.round_config")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

M.BONUS_POINTS = model.BONUS_POINTS
M.LEFT_WINDOW_MARGIN = gutter.LEFT_WINDOW_MARGIN
M.STACK_Y_LIFT_PX = gutter.STACK_Y_LIFT_PX

local TRANSFORM_DISSOLVE_TIME = 0.7
local TRANSFORM_MATERIALIZE_TIME = 0.6
local TRANSFORM_TOTAL = TRANSFORM_DISSOLVE_TIME + TRANSFORM_MATERIALIZE_TIME + 0.1
local BURN_DISSOLVE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD, G.C.MUTED_GREY }
local BURN_MATERIALIZE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.WHITE }
local BACKDROP_FILL_ALPHA = 0.18
local BACKDROP_LINE_ALPHA = 0.28

function M.is_animating()
	return model.is_animating()
end

function M.is_bonus_card(card)
	return model.is_bonus_card(card)
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
	return model.is_active()
end

function M.cards()
	return model.cards()
end

function M.set_cards(cards)
	M.stage_cards(cards)
end

function M.clear()
	model.clear()
end

function M.stage_cards(cards)
	local staged = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			staged[#staged + 1] = card
		end
	end
	model.set_cards(staged)
	model.set_animating(#staged > 0)
end

function M.on_hand_start(set, hand_index)
	model.on_hand_start(set, hand_index)
	if round_config.is_bonus_stack_hand(set, hand_index) and not model.is_animating() then
		M.sync_positions()
	end
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
	model.mark_bonus_card(card)
	M.apply_gold_bonus_face(card)
end

local function reconcile_bonus_faces()
	for _, card in ipairs(model.cards() or {}) do
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

function M.stack_y_lift()
	return gutter.stack_y_lift()
end

function M.stack_layout()
	return gutter.stack_layout()
end

function M.clears_gameplay_bounds()
	local layout = M.stack_layout()
	local left_edge = gameplay_left_edge()
	return layout.x + layout.card_w + layout.clearance <= left_edge + 0.02
end

function M.target_position(index)
	return gutter.target_position(index)
end

function M.stack_index(card)
	return model.stack_index(card)
end

function M.contains(card)
	return model.contains(card)
end

function M.sync_positions()
	if not model.cards() or model.is_animating() then return end
	local placement = G.placement_table and G.placement_table.area
	for i, card in ipairs(model.cards() or {}) do
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
	model.set_animating(false)
	local promoted = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			M.become_bonus_card(card)
			promoted[#promoted + 1] = card
		end
	end
	model.set_cards(promoted)
	model.set_animating(false)
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
	local cards = model.cards() or {}
	local card_delay = opts.card_delay or 0.45
	local stagger = opts.stagger or 0.07
	local hold = opts.hold or 0.3
	local initial_delay = opts.initial_delay or 0

	if #cards == 0 then
		if opts.on_complete then opts.on_complete() end
		return
	end

	model.set_animating(true)

	local function finish()
		model.set_animating(false)
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
	if not model.is_animating() then
		M.sync_positions()
	end
end

function M.remove_card(card)
	model.remove_card(card)
	if model.is_active() then
		M.sync_positions()
	end
end

function M.return_card(card)
	return gutter.return_card(card)
end

function M.point_in_stack(x, y)
	return gutter.point_in_stack(x, y)
end

function M.drop_in_gutter(session, x, y)
	return gutter.drop_in_gutter(session, x, y)
end

function M.bonus_points_for(used_cards)
	return model.bonus_points_for(used_cards)
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
	word_feedback.show_screen_centered("Perk earned!", G.C and G.C.GOLD or { 1, 0.85, 0.2, 1 }, 1.1)
end

function M.consume_card(card)
	model.remove_card(card)
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
	return gutter.gutter_pixels(layout)
end

function M.draw_shadow()
	local cards = model.cards()
	if not cards or #cards == 0 then return end
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
	local cards = model.cards()
	if not cards then return end
	local layout = M.stack_layout()
	if M.is_active() and not model.is_animating() then
		draw_label(layout)
	end
	local dragging = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	local focused = G.INPUT and G.INPUT.focused and G.INPUT.focused.target
	for _, card in ipairs(cards) do
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
