--[[ word_game/ui/player_portrait.lua - Portrait hooks (image atlas removed). ]]

local M = {}

M.index = 0

M.NAMES = {
	[0] = "MILO",
	[1] = "ALEISHA",
	[2] = "MARCO",
	[3] = "PIP",
	[4] = "REED",
	[5] = "SAGE",
	[6] = "JULES",
	[7] = "COLE",
	[8] = "ATLAS",
	[9] = "NOVA",
	[10] = "QUINN",
	[11] = "DEX",
	[12] = "THEO",
	[13] = "ELENA",
	[14] = "MORSE",
	[15] = "VERA",
	[16] = "RORY",
	[17] = "WREN",
	[18] = "LANE",
}

function M.image_for(_index)
	return nil
end

function M.draw_at(_index, _rect, _show_name, _name, _name_rect, _brightness)
end

function M.draw()
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.draw then
		WORD_GAME.TimelineTimer.draw()
	end
end

function M.draw_ally()
end

function M.draw_guest()
end

function M.name_for_index(index)
	index = (index or 0) % 19
	return M.NAMES[index] or "PLAYER"
end

function M.current_name()
	return M.name_for_index(M.index or 0)
end

return M
