--[[ word_game/ui/hand_placement_recall_anim.lua - Slide placement-row cards back to hand ]]

local Scheduler = require "app.effects.timeline_scheduler"
local bonus_model = require "word_game.model.bonus_stack"
local bonus_gutter = require "word_game.board.bonus_gutter"

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
	if G.GAME then
		G.GAME.placement_recall_animating = active
	end
end

local function placement_area()
	return G.placement_table and G.placement_table.area
end

local function sync_placement_from_jumble()
	if not (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()) then return end
	local wr = G.GAME and G.GAME.word_round
	local slots = wr and wr.jumble and wr.jumble.slots
	if slots and WORD_GAME.Jumble.sync_placement_cards then
		WORD_GAME.Jumble.sync_placement_cards(slots)
	end
end

local function clear_jumble_slots()
	if not (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()) then return end
	local wr = G.GAME and G.GAME.word_round
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
			if G.placement_table then
				G.placement_table:on_remove_card(card)
			end
			if card.area == p_area then
				p_area:remove_card(card)
			end
			bonus_gutter.return_card(card)
			local tx, ty = card.T.x, card.T.y
			local tr = card.T.r or 0
			local arc = (G.CARD_H or 1.4) * ARC_FRAC
			park_card(card, sx, sy, sr)
			local started = G.TIMERS.REAL
			Scheduler.add{
				mode = "window",
				timer = "REAL",
				delay = SLIDE_DURATION,
				blockable = false,
				blocking = false,
				func = function()
					local u = math.min(1, (G.TIMERS.REAL - started) / SLIDE_DURATION)
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
			if not card or not G.hand or not p_area then return true end

			local sx, sy = card.T.x, card.T.y
			local sr = card.T.r or 0

			if G.placement_table then
				G.placement_table:on_remove_card(card)
			end
			if card.area == p_area then
				p_area:remove_card(card)
			end

			card.placement_recall_slide = true
			G.hand:emplace(card)

			local tx, ty, tr = card.T.x, card.T.y, card.T.r or 0
			local arc = (G.CARD_H or 1.4) * ARC_FRAC
			park_card(card, sx, sy, sr)

			local started = G.TIMERS.REAL
			Scheduler.add{
				mode = "window",
				timer = "REAL",
				delay = SLIDE_DURATION,
				blockable = false,
				blocking = false,
				func = function()
					local u = math.min(1, (G.TIMERS.REAL - started) / SLIDE_DURATION)
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
	if G.hand then
		for _, card in ipairs(G.hand.cards or {}) do
			card.placement_recall_slide = nil
		end
	end

	if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
		local wr = G.GAME and G.GAME.word_round
		local slots = wr and wr.jumble and wr.jumble.slots
		if slots and WORD_GAME.Jumble.sync_placement_cards then
			WORD_GAME.Jumble.sync_placement_cards(slots)
		end
		if G.placement_table and G.placement_table.jumble_geometry then
			G.placement_table.jumble_geometry.relayout(G.placement_table)
		end
	end

	local placement_word = require("word_game.model.placement_word")
	placement_word.clear()

	local area = placement_area()
	if area and area.hard_set_cards then
		area:hard_set_cards()
	end

	if G.hand then
		if G.hand.clear_selection then G.hand:clear_selection() end
		if G.hand.set_ranks then G.hand:set_ranks() end
		if G.hand.relayout then G.hand:relayout() end
		if G.hand.hard_set_cards then G.hand:hard_set_cards() end
		if G.hand.snap_VT then G.hand:snap_VT() end
	end
end

function M.animate(on_complete)
	if animating or not G.hand or not placement_area() then
		if on_complete then on_complete() end
		return false
	end

	local cards = collect_cards()
	if #cards == 0 then
		if on_complete then on_complete() end
		return false
	end

	if not (G.TIMELINE and G.TIMELINE.enqueue) then
		return false
	end

	set_animating(true)
	clear_jumble_slots()

	local p_area = placement_area()
	for i, card in ipairs(cards) do
		if bonus_model.is_bonus_card(card) then
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
