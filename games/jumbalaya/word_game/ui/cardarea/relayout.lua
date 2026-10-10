--[[ word_game/ui/cardarea/relayout.lua - Layout from pile hosts (hand / draw / pattern / discard) ]]

local game = require("word_game.ui.util.game_runtime").game

local hand = require("word_game.ui.cardarea.hand")
local deck = require("word_game.ui.cardarea.deck")
local placement = require("word_game.ui.cardarea.placement")

local M = {}

function M.relayout(area, face_down_in_pile)
	if not area.cards then return end
	if (area == game().dealt_letters or area == game().draw_pile or area == game().recycle_stash) and game().view_deck and game().view_deck[1] and game().view_deck[1].cards then return end

	deck.relayout(area)
	hand.relayout(area)

	if area.config.type == "discard" or area.config.type == "bonus" then
		for k, card in ipairs(area.cards) do
			face_down_in_pile(card)
			if not card.states.drag.is then
				card.T.x = area.T.x + (area.T.w - card.T.w) * card.discard_pos.x
				card.T.y = area.T.y + (area.T.h - card.T.h) * card.discard_pos.y
				card.T.r = card.discard_pos.r
			end
		end
	end

	placement.relayout(area)

	for k, card in ipairs(area.cards) do
		card.slot = k
	end
	if area.children.view_deck then
		area.children.view_deck:set_role{major = area.cards[1] or area}
	end
end

return M
