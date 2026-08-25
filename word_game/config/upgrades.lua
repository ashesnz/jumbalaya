--[[ word_game/config/upgrades.lua - Per-card Upgrade definitions ]]

local M = {
	double = {
		key = "double",
		name = "Double Letter",
		description = "This card's AP ×2",
		abbrev = "×2",
		price = 4,
		tier = 1,
	},
	triple = {
		key = "triple",
		name = "Triple Letter",
		description = "This card's AP ×3",
		abbrev = "×3",
		price = 7,
		tier = 2,
	},
	steel = {
		key = "steel",
		name = "Steel Letter",
		description = "Never spent when played — stays in hand",
		abbrev = "ST",
		price = 9,
		tier = 3,
	},
	echo = {
		key = "echo",
		name = "Echo Letter",
		description = "This card scores twice when played",
		abbrev = "EC",
		price = 10,
		tier = 3,
	},
	glass = {
		key = "glass",
		name = "Glass Letter",
		description = "+3 Boost, then shatters after one use",
		abbrev = "GL",
		price = 12,
		tier = 3,
	},
}

M.ORDER = { "double", "triple", "steel", "echo", "glass" }
M.GLASS_BOOST = 3

function M.get(key)
	return M[key]
end

function M.ap_multiplier(key)
	if key == "double" then return 2 end
	if key == "triple" then return 3 end
	if key == "echo" then return 2 end
	return 1
end

return M
