--[[ word_game/ui/play_effects/hand_clear/clear_table.lua - Remove hand and pattern cards on stage clear ]]

local facade = require("word_game.ui.facade")
local game = require("word_game.ui.util.game_runtime").game

local M = {}

function M.clear_now()
	local Deck = facade.deck()
	if Deck.clear_hand_and_placement then
		Deck.clear_hand_and_placement()
	end

	local Jumble = facade.jumble()
	local wr = facade.game_access().word_round()
	local j = wr and wr.jumble
	if j and j.slots then
		if Jumble.clear_blank_cards then
			Jumble.clear_blank_cards(j.slots)
		end
		if Jumble.sync_placement_cards then
			Jumble.sync_placement_cards(j.slots)
		end
	end

	local g = game()
	for _, key in ipairs({ "dealt_letters", "recycle_stash" }) do
		local area = g[key]
		if area and area.cards then
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if card and card.remove_from_area then
					card:remove_from_area()
				end
			end
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
	end

	local pattern = g.pattern_row and g.pattern_row.area
	if pattern and pattern.cards then
		for i = #pattern.cards, 1, -1 do
			local card = pattern.cards[i]
			if card and card.remove_from_area then
				card:remove_from_area()
			end
		end
		if pattern.hard_set_cards then
			pattern:hard_set_cards()
		end
	end

	if WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	end

	if Deck.commit_pile_hosts then
		Deck.commit_pile_hosts({ "hand", "draw", "discard", "pattern" })
	end
end

return M
