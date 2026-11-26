--[[
	word_game/model/jumble/boss_gutter_cards.lua - Resolve live boss-hand tiles for gutter animation
]]

local live_game = require("word_game.model.live_game")
local core_jumble = require("jumbalaya_core.rules.jumble")

local M = {}

local function append_live_card(cards, seen, card)
	local live = require("word_game.model.piles").resolve_live_card(card)
	if live and not live.REMOVED and not seen[live] then
		seen[live] = true
		cards[#cards + 1] = live
	end
end

function M.for_clear(j, used_cards)
	local cards = {}
	local seen = {}

	if j and j.boss_cards then
		for _, record in ipairs(j.boss_cards) do
			append_live_card(cards, seen, record)
		end
	end
	if #cards > 0 then
		return cards
	end

	for _, card in ipairs(used_cards or {}) do
		append_live_card(cards, seen, card)
	end
	if #cards > 0 then
		return cards
	end

	if j and j.slots then
		for _, card in ipairs(core_jumble.collect_used_cards(j.slots)) do
			append_live_card(cards, seen, card)
		end
	end
	if #cards > 0 then
		return cards
	end

	local g = live_game()
	local area = g and g.pattern_row and g.pattern_row.area
	if area then
		for _, card in ipairs(area.cards or {}) do
			append_live_card(cards, seen, card)
		end
	end
	return cards
end

return M