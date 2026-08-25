--[[ word_game/config/wildcards.lua - Single-use Wildcard definitions ]]

local M = {
	second_wind = {
		key = "second_wind",
		name = "Second Wind",
		description = "Grants one extra word-play this Hand",
		price = 5,
	},
	wild_twin = {
		key = "wild_twin",
		name = "Wild Twin",
		description = "The next word played counts as containing a Twin",
		price = 6,
	},
	alphabet_soup = {
		key = "alphabet_soup",
		name = "Alphabet Soup",
		description = "Add 1 of 2 letters from a random AP row to your deck",
		price = 5,
	},
}

M.ORDER = { "second_wind", "wild_twin", "alphabet_soup" }

function M.get(key)
	return M[key]
end

return M
