--[[ word_game/model/table_areas.lua - TABLE_BOARD CardArea instances on G.

	Prefer WORD_GAME.Deck / Board accessors in new code; these globals remain
	the live runtime bus for CardArea instances.
]]

local M = {}

--- Legacy save cardAreas keys → current G property names.
M.SAVE_ALIASES = {
	hand = "dealt_letters",
	deck = "draw_pile",
	discard = "recycle_stash",
	placement_table = "pattern_row",
	placement_slots = "pattern_row",
}

function M.resolve_save_key(name)
	return M.SAVE_ALIASES[name] or name
end

function M.dealt_letters()
	return G and G.dealt_letters
end

function M.draw_pile()
	return G and G.draw_pile
end

function M.recycle_stash()
	return G and G.recycle_stash
end

function M.pattern_row()
	return G and G.pattern_row
end

function M.pattern_row_area()
	local row = G and G.pattern_row
	return row and row.area
end

return M
