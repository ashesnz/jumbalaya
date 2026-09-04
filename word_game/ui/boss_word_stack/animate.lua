--[[ word_game/ui/boss_word_stack/animate.lua - Gold transform and fly-to-gutter choreography ]]

local model = require("word_game.model.bonus_stack")
local layout = require("word_game.ui.boss_word_stack.layout")
local DissolveFX = require("app.effects.dissolve_fx")

local M = {}

local TRANSFORM_DISSOLVE_TIME = 0.7
local TRANSFORM_MATERIALIZE_TIME = 0.6
local TRANSFORM_TOTAL = TRANSFORM_DISSOLVE_TIME + TRANSFORM_MATERIALIZE_TIME + 0.1
local BURN_DISSOLVE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.RED, G.C.GOLD, G.C.MUTED_GREY }
local BURN_MATERIALIZE_COLOURS = { G.C.BLACK, G.C.ORANGE, G.C.GOLD, G.C.WHITE }

local function stack()
	return require("word_game.ui.boss_word_stack")
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
	local S = stack()
	if not card or not DissolveFX or not DissolveFX.run then
		S.become_bonus_card(card)
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
			S.become_bonus_card(card)
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
	local tx, ty = layout.target_position(fly_index)
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
	local S = stack()
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

	local function reconcile_bonus_faces()
		for _, card in ipairs(model.cards() or {}) do
			if card and card.bonus_card and not card.REMOVED then
				S.apply_gold_bonus_face(card)
			end
		end
	end

	local function finish()
		model.set_animating(false)
		reconcile_bonus_faces()
		if opts.on_complete then opts.on_complete() end
	end

	local can_queue = queue_event and G.TIMELINE and G.TIMELINE.enqueue
	if not can_queue then
		for index, card in ipairs(cards) do
			S.become_bonus_card(card)
			local tx, ty = layout.target_position(index)
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
						S.detach(fly_card)
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
				local tx, ty = layout.target_position(index)
				snap_card_to(card, tx, ty)
			end
			finish()
			return true
		end,
	}))
end

return M
