--[[ word_game/model/table_areas.lua - Store selectors for table card piles ]]

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
	if G and G._store then
		return G._store:get()
	end
	return nil
end

-- Store selectors
function M.hand_cards(state)
	local s = get_store_state(state)
	if s and s.piles then
		return s.piles.hand
	end
	return G and G.dealt_letters and G.dealt_letters.cards or {}
end

function M.draw_cards(state)
	local s = get_store_state(state)
	if s and s.piles then
		return s.piles.draw
	end
	return G and G.draw_pile and G.draw_pile.cards or {}
end

function M.recycle_cards(state)
	local s = get_store_state(state)
	if s and s.piles then
		return s.piles.discard
	end
	return G and G.recycle_stash and G.recycle_stash.cards or {}
end

function M.pattern_cards(state)
	local s = get_store_state(state)
	if s and s.piles then
		return s.piles.pattern
	end
	return G and G.pattern_row and G.pattern_row.area and G.pattern_row.area.cards or {}
end

function M.bonus_cards(state)
	local s = get_store_state(state)
	if s and s.piles then
		return s.piles.bonus
	end
	return G and G.bonus_stack and G.bonus_stack.cards or {}
end

-- Legacy accessors for backwards compatibility with CardArea expectations
function M.dealt_letters()
	if G and G.dealt_letters then return G.dealt_letters end
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
	if G and G.draw_pile then return G.draw_pile end
	return {
		cards = M.draw_cards(),
		config = { card_limit = 52 },
	}
end

function M.recycle_stash()
	if G and G.recycle_stash then return G.recycle_stash end
	return {
		cards = M.recycle_cards(),
	}
end

function M.pattern_row()
	if G and G.pattern_row then return G.pattern_row end
	return {
		cards = M.pattern_cards(),
		area = M.pattern_row_area(),
	}
end

function M.pattern_row_area()
	local row = G and G.pattern_row
	if row and row.area then return row.area end
	return {
		cards = M.pattern_cards(),
		load = function() end,
		save = function() return {} end,
	}
end

return M
