--[[ word_game/ui/hand_placement_recall_anim.lua - Slide placement-row cards back to hand ]]

local Scheduler = require "app.effects.scheduler"
local CardMotion = require "app.effects.card_motion"

local M = {}

local animating = false

local STAGGER = 0.07
local MOVE_DELAY = 0.12
local FINISH_PAD = 0.08

function M.is_animating()
	return animating
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

local function collect_cards()
	sync_placement_from_jumble()
	local area = placement_area()
	if not area or not area.cards then return {} end
	local cards = {}
	for _, card in ipairs(area.cards) do
		cards[#cards + 1] = card
	end
	return cards
end

local function finish_recall()
	if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
		local wr = G.GAME and G.GAME.word_round
		local slots = wr and wr.jumble and wr.jumble.slots
		if slots then
			WORD_GAME.Jumble.clear_blank_cards(slots)
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
	local p_area = placement_area()

	for i, card in ipairs(cards) do
		Scheduler.add{
			mode = "window",
			delay = (i - 1) * STAGGER,
			blocking = true,
			func = function()
				if G.placement_table then
					G.placement_table:on_remove_card(card)
				end
				CardMotion.move{
					from = p_area,
					to = G.hand,
					card = card,
					direction = "down",
					percent = 50,
					delay = MOVE_DELAY,
					stay_flipped = false,
				}
				return true
			end,
		}
	end

	local tail = (#cards > 0 and ((#cards - 1) * STAGGER + MOVE_DELAY) or 0) + FINISH_PAD
	Scheduler.add{
		mode = "delayed",
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

return M
