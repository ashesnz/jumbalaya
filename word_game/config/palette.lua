--[[
	word_game/config/palette.lua - the Jumbalaya colour system.

	Pure data: every entry is either an RGB(A) hex string or a literal
	colour table. `build()` converts it into the live `G.C` table using a
	hex-conversion helper supplied by the caller, so this module has no
	engine dependencies and can be required at any time.

	Identity: deep slate-ink surfaces, paper-tinted neutrals, and spice-drawer
	accents; interactive elements use a teal "pressed tile" hue rather than
	the generic blue/red pairing.
]]

---@class PaletteSpec
local M = {}

--- Colours converted through `hex`; keys mirror G.C's public surface.
M.HEX = {
	MULTIPLIER = 'E0564F',
	POINTS = '4C7DE0',
	MONEY = 'EFBF5A',
	XMULT = 'E0564F',
	FILTER = 'F58730',
	BLUE = '4C7DE0',
	RED = 'E0564F',
	GREEN = '58BE8B',
	PALE_GREEN = '79AE93',
	ORANGE = 'F49B33',
	IMPORTANT = 'FFB13D',
	GOLD = 'E3B04B',
	PURPLE = '9068B8',
	BLACK = '2B383D',
	L_BLACK = '41555C',
	GREY = '5F7A80',
	CHANCE = '58BE8B',
	MUTED_GREY = 'C6CED8',
	BOOSTER = '7A63C2',

	DYN_UI = {
		MAIN = '39525A',
		DARK = '2B383D',
		BOSS_MAIN = '2B383D',
		BOSS_DARK = '232E32',
	},
	UI = {
		TEXT_DARK = '41555C',
		TEXT_INACTIVE = '96A0A699',
		BACKGROUND_DARK = '7FA3A4',
		BACKGROUND_INACTIVE = '6E7679FF',
		OUTLINE_LIGHT = 'E4E8EA',
		TRANSPARENT_LIGHT = 'F2F5F522',
		TRANSPARENT_DARK = '1A222522',
		HOVER = '00000055',
		BUTTON = '12897F',
		BUTTON_HOVER = '1BA79B',
		BUTTON_OUTLINE = '12897F',
		BUTTON_TEXT = 'F0FBF8',
	},
	SET = {
		Default = 'D3DEE1',
		Enhanced = 'D3DEE1',
		Companion = '3A4E54',
		Charm = '3A4E54',
		Orbit = '3A4E54',
		Phantom = '3A4E54',
		Perk = '3A4E54',
	},
	SECONDARY_SET = {
		Default = 'A3BFC6',
		Enhanced = '8B91E0',
		Companion = '77A0A6',
		Charm = 'B183D8',
		Orbit = '2FBCC9',
		Phantom = '4E8CF5',
		Perk = 'F26F35',
		Finish = '52B09A',
	},

	BACKGROUND = {
		C = '2B383D',
	},
}

--- Literal RGBA tables that bypass hex conversion.
M.LITERAL = {
	YELLOW = {1, 1, 0, 1},
	CLEAR = {0, 0, 0, 0},
	WHITE = {1, 1, 1, 1},
	FINISH = {1, 1, 1, 1},
	DARK_FINISH = {0, 0, 0, 1},
	UI = {
		TEXT_LIGHT = {1, 1, 1, 1},
		BACKGROUND_WHITE = {1, 1, 1, 1},
	},
	BACKGROUND = {
		L = {1, 1, 0, 1},
		D = {0, 1, 1, 1},
		contrast = 1,
	},
}

--- Rarity tints, ordered common -> legendary.
M.RARITY = { '4C7DE0', '58BE8B', 'E0564F', 'C06CBF' }

--- Recursively merges `source` into `target`, converting hex strings via
--- `hex`; literal tables are cloned through recursion as-is.
local function convert(value, hex)
	if type(value) == 'string' then return hex(value) end
	if type(value) == 'table' then
		local out = {}
		for k, v in pairs(value) do out[k] = convert(v, hex) end
		return out
	end
	return value
end

--- Builds the full colour table.
---@param hex fun(input: string): table RGBA converter
---@return table colours ready to assign to G.C
function M.build(hex)
	local colours = {}
	for key, value in pairs(M.HEX) do colours[key] = convert(value, hex) end
	for key, value in pairs(M.LITERAL) do
		local converted = convert(value, hex)
		if type(converted) == 'table' and type(colours[key]) == 'table' then
			for k, v in pairs(converted) do colours[key][k] = v end
		else
			colours[key] = converted
		end
	end

	colours.RARITY = {}
	for i, entry in ipairs(M.RARITY) do colours.RARITY[i] = hex(entry) end
	return colours
end

return M
