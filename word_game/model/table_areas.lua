--[[ word_game/model/table_areas.lua - Store selectors for table card piles ]]

local live_game = require("word_game.model.live_game")

local M = {}

--- Legacy save cardAreas keys → G property names.
M.SAVE_ALIASES = {
	hand = "dealt_letters",
	dealt_letters = "dealt_letters",
	deck = "draw_pile",
	draw_pile = "draw_pile",
	discard = "recycle_stash",
	recycle_stash = "recycle_stash",
	placement_table = "pattern_row",
	placement_slots = "pattern_row",
	pattern_row = "pattern_row",
}

function M.resolve_save_key(name)
	return M.SAVE_ALIASES[name] or name
end

local function get_store_state(state)
	if state then return state end
	local BridgeRuntime = require("bridge.runtime")
	local store = BridgeRuntime.store()
	if store then
		return store:get()
	end
	return nil
end

local function pile_or_host(state, pile_id, host_cards_fn)
	local s = get_store_state(state)
	if s and s.piles and s.piles[pile_id] and #s.piles[pile_id] > 0 then
		return s.piles[pile_id]
	end
	return host_cards_fn()
end

-- Store selectors (prefer non-empty store piles; fall back to live hosts for headless tests)
function M.hand_cards(state)
	return pile_or_host(state, "hand", function()
		return live_game() and live_game().dealt_letters and live_game().dealt_letters.cards or {}
	end)
end

function M.draw_cards(state)
	return pile_or_host(state, "draw", function()
		return live_game() and live_game().draw_pile and live_game().draw_pile.cards or {}
	end)
end

function M.recycle_cards(state)
	return pile_or_host(state, "discard", function()
		return live_game() and live_game().recycle_stash and live_game().recycle_stash.cards or {}
	end)
end

function M.pattern_cards(state)
	return pile_or_host(state, "pattern", function()
		return live_game() and live_game().pattern_row and live_game().pattern_row.area
			and live_game().pattern_row.area.cards or {}
	end)
end

function M.bonus_cards(state)
	return pile_or_host(state, "bonus", function()
		return live_game() and live_game().bonus_stack and live_game().bonus_stack.cards or {}
	end)
end

-- Legacy accessors for backwards compatibility with CardPile expectations
function M.dealt_letters()
	if live_game() and live_game().dealt_letters then return live_game().dealt_letters end
	return {
		cards = M.hand_cards(),
		config = { card_limit = 7, selected_limit = 7 },
		emplace = function(self, card) table.insert(self.cards, card) end,
		remove_card = function(self, card)
			for i, c in ipairs(self.cards) do
				if c == card or c.id == card.id then
					table.remove(self.cards, i)
					break
				end
			end
		end,
		set_ranks = function() end,
		relayout = function() end,
	}
end

function M.draw_pile()
	if live_game() and live_game().draw_pile then return live_game().draw_pile end
	return {
		cards = M.draw_cards(),
		config = { card_limit = 52 },
	}
end

function M.recycle_stash()
	if live_game() and live_game().recycle_stash then return live_game().recycle_stash end
	return {
		cards = M.recycle_cards(),
	}
end

function M.pattern_row()
	if live_game() and live_game().pattern_row then return live_game().pattern_row end
	return {
		cards = M.pattern_cards(),
		area = M.pattern_row_area(),
	}
end

function M.pattern_row_area()
	local row = live_game() and live_game().pattern_row
	if row and row.area then return row.area end
	return {
		cards = M.pattern_cards(),
		load = function() end,
		save = function() return {} end,
	}
end

return M
