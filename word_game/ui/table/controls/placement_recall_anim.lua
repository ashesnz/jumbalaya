--[[ word_game/ui/table/controls/placement_recall_anim.lua - Slide placement-row cards back to hand ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Scheduler = require "app.effects.timeline_scheduler"
local game_access = require("word_game.model.game_access")
local domain = require "word_game.ui.facade"

local M = {}

local animating = false

local STAGGER = 0.08
local SLIDE_DURATION = 0.38
local ARC_FRAC = 0.12
local FINISH_PAD = 0.05

function M.is_animating()
	return animating
end

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

local function set_animating(active)
	animating = active
	game_access.patch({ placement_recall_animating = active })
end

local function placement_area()
	return runtime().pattern_row and runtime().pattern_row.area
end

local function bonus_stack_ui()
	return WORD_GAME_UI.BonusStackUI
end

local function sync_placement_from_jumble()
	if not (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()) then return end
	local wr = game_access.word_round()
	local slots = wr and wr.jumble and wr.jumble.slots
	if slots and WORD_GAME.Jumble.sync_placement_cards then
		WORD_GAME.Jumble.sync_placement_cards(slots)
	end
end

local function clear_jumble_slots()
	if not (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()) then return end
	local wr = game_access.word_round()
	local slots = wr and wr.jumble and wr.jumble.slots
	if slots and WORD_GAME.Jumble.clear_blank_cards then
		WORD_GAME.Jumble.clear_blank_cards(slots)
	end
end

local function collect_cards()
	sync_placement_from_jumble()
	local area = placement_area()
	if not area or not area.cards then return {} end
	local cards = {}
	for _, card in ipairs(area.cards) do
		cards[#cards + 1] = card
	end
	table.sort(cards, function(a, b)
		return a.T.x + a.T.w * 0.5 < b.T.x + b.T.w * 0.5
	end)
	return cards
end

local function park_card(card, x, y, r)
	card.T.x = x
	card.T.y = y
	card.T.r = r or 0
	if card.VT then
		card.VT.x = x
		card.VT.y = y
		card.VT.r = card.T.r
	end
	if card.velocity then
		card.velocity.x = 0
		card.velocity.y = 0
		card.velocity.r = 0
	end
end

local function sync_card_transform(card)
	if card.VT then
		card.VT.x = card.T.x
		card.VT.y = card.T.y
		card.VT.r = card.T.r
	end
end

local function slide_card_to_bonus_stack(card, p_area, delay)
	Scheduler.add{
		mode = "delayed",
		timer = "REAL",
		delay = delay,
		blockable = false,
		func = function()
			if not card or not p_area then return true end
			local sx, sy = card.T.x, card.T.y
			local sr = card.T.r or 0
			if runtime().pattern_row then
				runtime().pattern_row:on_remove_card(card)
			end
			if card.area == p_area then
				p_area:remove_card(card)
			end
			local stack = bonus_stack_ui()
			if stack and stack.return_card then
				stack.return_card(card)
			end
			local tx, ty = card.T.x, card.T.y
			local tr = card.T.r or 0
			local arc = (runtime().CARD_H or 1.4) * ARC_FRAC
			park_card(card, sx, sy, sr)
			local started = runtime().TIMERS.REAL
			Scheduler.add{
				mode = "window",
				timer = "REAL",
				delay = SLIDE_DURATION,
				blockable = false,
				blocking = false,
				func = function()
					local u = math.min(1, (runtime().TIMERS.REAL - started) / SLIDE_DURATION)
					local e = smoothstep(u)
					card.T.x = sx + (tx - sx) * e
					card.T.y = sy + (ty - sy) * e - arc * math.sin(math.pi * u)
					card.T.r = sr + (tr - sr) * e
					sync_card_transform(card)
					if u >= 1 then
						card.T.x = tx
						card.T.y = ty
						card.T.r = tr
						sync_card_transform(card)
						return true
					end
				end,
			}
			if play_sfx then
				play_sfx("card_slide1", 0.88 + delay * 0.15, 0.55)
			end
			return true
		end,
	}
end

local function slide_card_to_hand(card, p_area, delay)
	Scheduler.add{
		mode = "delayed",
		timer = "REAL",
		delay = delay,
		blockable = false,
		func = function()
			if not card or not runtime().dealt_letters or not p_area then return true end

			local sx, sy = card.T.x, card.T.y
			local sr = card.T.r or 0

			if runtime().pattern_row then
				runtime().pattern_row:on_remove_card(card)
			end
			if card.area == p_area then
				p_area:remove_card(card)
			end

			card.placement_recall_slide = true
			runtime().dealt_letters:emplace(card)

			local tx, ty, tr = card.T.x, card.T.y, card.T.r or 0
			local arc = (runtime().CARD_H or 1.4) * ARC_FRAC
			park_card(card, sx, sy, sr)

			local started = runtime().TIMERS.REAL
			Scheduler.add{
				mode = "window",
				timer = "REAL",
				delay = SLIDE_DURATION,
				blockable = false,
				blocking = false,
				func = function()
					local u = math.min(1, (runtime().TIMERS.REAL - started) / SLIDE_DURATION)
					local e = smoothstep(u)
					card.T.x = sx + (tx - sx) * e
					card.T.y = sy + (ty - sy) * e - arc * math.sin(math.pi * u)
					card.T.r = sr + (tr - sr) * e
					sync_card_transform(card)
					if u >= 1 then
						card.T.x = tx
						card.T.y = ty
						card.T.r = tr
						sync_card_transform(card)
						card.placement_recall_slide = nil
						return true
					end
				end,
			}

			if play_sfx then
				play_sfx("card_slide1", 0.88 + delay * 0.15, 0.55)
			end
			return true
		end,
	}
end

local function finish_recall()
	if runtime().dealt_letters then
		for _, card in ipairs(runtime().dealt_letters.cards or {}) do
			card.placement_recall_slide = nil
		end
	end

	if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
		local wr = game_access.word_round()
		local slots = wr and wr.jumble and wr.jumble.slots
		if slots and WORD_GAME.Jumble.sync_placement_cards then
			WORD_GAME.Jumble.sync_placement_cards(slots)
		end
		if runtime().pattern_row and runtime().pattern_row.jumble_geometry then
			runtime().pattern_row.jumble_geometry.relayout(runtime().pattern_row)
		end
	end

	domain.placement_word().clear()

	local area = placement_area()
	if area and area.hard_set_cards then
		area:hard_set_cards()
	end

	if runtime().dealt_letters then
		if runtime().dealt_letters.clear_selection then runtime().dealt_letters:clear_selection() end
		if runtime().dealt_letters.set_ranks then runtime().dealt_letters:set_ranks() end
		if runtime().dealt_letters.relayout then runtime().dealt_letters:relayout() end
		if runtime().dealt_letters.hard_set_cards then runtime().dealt_letters:hard_set_cards() end
		if runtime().dealt_letters.snap_VT then runtime().dealt_letters:snap_VT() end
	end
end

function M.animate(on_complete)
	if animating or not runtime().dealt_letters or not placement_area() then
		if on_complete then on_complete() end
		return false
	end

	local cards = collect_cards()
	if #cards == 0 then
		if on_complete then on_complete() end
		return false
	end

	if not (runtime().TIMELINE and runtime().TIMELINE.enqueue) then
		return false
	end

	set_animating(true)
	clear_jumble_slots()

	local p_area = placement_area()
	for i, card in ipairs(cards) do
		local stack = bonus_stack_ui()
		if stack and stack.is_bonus_card(card) then
			slide_card_to_bonus_stack(card, p_area, (i - 1) * STAGGER)
		else
			slide_card_to_hand(card, p_area, (i - 1) * STAGGER)
		end
	end

	local tail = (#cards > 0 and ((#cards - 1) * STAGGER + SLIDE_DURATION) or 0) + FINISH_PAD
	Scheduler.add{
		mode = "delayed",
		timer = "REAL",
		delay = tail,
		blocking = true,
		func = function()
			finish_recall()
			set_animating(false)
			if on_complete then on_complete() end
			return true
		end,
	}

	return true
end

function M.reset()
	animating = false
end

return M
