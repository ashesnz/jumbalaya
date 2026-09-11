--[[ packages/jumbalaya_core/config/gameplay/letter_tiers.lua - Scrabble-style letter values (no G) ]]

local M = {}

M.TIERS = {
	{ value = 1, letters = { "A", "E", "I", "O", "U", "L", "N", "S", "T", "R" } },
	{ value = 2, letters = { "D", "G" } },
	{ value = 3, letters = { "B", "C", "M", "P" } },
	{ value = 4, letters = { "F", "H", "V", "W", "Y" } },
	{ value = 5, letters = { "K" } },
	{ value = 8, letters = { "J", "X" } },
	{ value = 10, letters = { "Q", "Z" } },
}

M.LETTER_VALUE = {}
for _, tier in ipairs(M.TIERS) do
	for _, letter in ipairs(tier.letters) do
		M.LETTER_VALUE[letter] = tier.value
	end
end

function M.value_for(letter)
	if not letter then return 0 end
	return M.LETTER_VALUE[letter:upper()] or 0
end

return M
