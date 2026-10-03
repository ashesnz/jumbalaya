--[[
	word_game/model/cards/deck/jumble_lifecycle.lua - Jumble deck populate, clear hand/placement, destroy boss cards

	Core: jumbalaya_core.cards.letter_card
	Store: piles via context.commit_piles
	Presentation: none
]]

local live_game = require("word_game.model.live_game")
local core_letter_card = require("jumbalaya_core.cards.letter_card")
local game_access = require("word_game.model.game_access")
local piles = require("word_game.model.piles")

local M = {}
local Shared = require("word_game.model.cards.deck.shared")
local function Deck()
	return package.loaded["word_game.model.cards.deck"]
end


	local bonus_return = require("word_game.model.jumble.bonus_return")

	local function reset_deck_pile()
		if not live_game().draw_pile then return end
		if live_game().draw_pile.cards then
			for i = #live_game().draw_pile.cards, 1, -1 do
				local card = live_game().draw_pile.cards[i]
				if card and card.remove_from_area then
					card:remove_from_area()
				end
			end
			live_game().draw_pile.cards = {}
		end
		if live_game().draw_pile.hard_set_cards then
			live_game().draw_pile:hard_set_cards()
		end
	end

	local function purge_table_cards()
		local function purge(area)
			if not area or not area.cards or not area.remove_card then return end
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if live_game().pattern_row and area == live_game().pattern_row.area then
					live_game().pattern_row:on_remove_card(card)
				end
				area:remove_card(card)
			end
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
		purge(live_game().dealt_letters)
		purge(live_game().recycle_stash)
		purge(live_game().pattern_row and live_game().pattern_row.area)
	end

	function M.is_jumble_deck()
		local wr = game_access.word_round()
		return wr and wr.mode == "jumble"
	end

	--- Ensure every inventory draw candidate is reflected in the draw pile store snapshot.
	--- Needed after marketplace draft: commit_hosts clears the draw host for chrome.
	function M.reconcile_draw_pile_from_inventory()
		if not M.is_jumble_deck() then return end
		local g = live_game()
		local draw = g.draw_pile
		if not draw or not draw.emplace then return end

		piles.hydrate_hosts_from_store({ "draw" })

		local function card_in_draw(card)
			for _, c in ipairs(draw.cards or {}) do
				if c == card then return true end
			end
			return false
		end

		local draw_limit = 0
		for _, card in ipairs(core_letter_card.collect_active_cards(g.letter_inventory)) do
			if not core_letter_card.is_jumble_draw_candidate(card) then
				goto continue
			end
			draw_limit = draw_limit + 1
			local area = card.area
			if area and area ~= draw then
				goto continue
			end
			if not card_in_draw(card) then
				if card.remove_from_area then
					card:remove_from_area()
				end
				draw:emplace(card)
			end
			::continue::
		end

		draw.config = draw.config or {}
		draw.config.card_limit = math.max(draw.config.card_limit or 0, draw_limit)
		if draw.hard_set_T then
			draw:hard_set_T()
		end
		Shared.commit_piles({ "draw" })
		Deck().sync_deck_count_display()
	end

	function M.populate_jumble_deck()
		purge_table_cards()
		if #(live_game().letter_inventory or {}) == 0 then
			Deck().populate_starting_deck()
			return
		end
		reset_deck_pile()
		for _, card in ipairs(live_game().letter_inventory) do
			if core_letter_card.is_jumble_draw_candidate(card) then
				if card.remove_from_area then
					card:remove_from_area()
				end
				card.played_pool = nil
				card.discard_stash = nil
				if card.states then
					card.states.visible = true
				end
				if live_game().draw_pile.emplace then
					live_game().draw_pile:emplace(card)
				end
			end
		end
		if live_game().draw_pile.config then
			live_game().draw_pile.config.card_limit = #live_game().draw_pile.cards
		end
		Deck().shuffle_deck()
		if live_game().draw_pile.hard_set_T then
			live_game().draw_pile:hard_set_T()
		end
		Shared.commit_piles({ "hand", "draw", "discard", "pattern" })
	end

	function M.clear_hand_and_placement()
		local area = live_game().pattern_row and live_game().pattern_row.area
		if area and area.cards then
			for i = #area.cards, 1, -1 do
				local card = area.cards[i]
				if live_game().pattern_row then
					live_game().pattern_row:on_remove_card(card)
				end
				area:remove_card(card)
				if card.bonus_card then
					bonus_return.return_card(card)
				elseif card.boss_temp then
					Deck().destroy_card(card)
				end
			end
			area:hard_set_cards()
		end
		if live_game().dealt_letters and live_game().dealt_letters.cards then
			for i = #live_game().dealt_letters.cards, 1, -1 do
				local card = live_game().dealt_letters.cards[i]
				live_game().dealt_letters:remove_card(card)
				if card.bonus_card then
					bonus_return.return_card(card)
				elseif card.boss_temp then
					Deck().destroy_card(card)
				end
			end
		end
	end

	function M.destroy_boss_cards()
		local wr = game_access.word_round()
		local j = wr and wr.jumble
		if not j or not j.boss_cards then return end
		for _, card in ipairs(j.boss_cards) do
			if card and not card.REMOVED then
				if card.area then
					card.area:remove_card(card)
				end
				Deck().destroy_card(card)
			end
		end
		game_access.dispatch({ type = "JUMBLE_SET_BOSS_CARDS" })
	end
return M
