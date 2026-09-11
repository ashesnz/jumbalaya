--[[ packages/jumbalaya_core/cards/deck_config.lua - Static deck tuning (no G) ]]

local M = {}

M.STARTING_LETTERS = { "E", "E", "A", "A", "I", "O", "T", "S", "R", "Y", "N", "C" }

M.COMMON_LETTERS = {
	A = true,
	E = true,
	I = true,
	O = true,
	U = true,
	L = true,
	N = true,
	S = true,
	T = true,
	R = true,
}

function M.weighted_letter_bag()
	local bag = {}
	for i = 1, 26 do
		local letter = string.char(string.byte("A") + i - 1)
		local weight = M.COMMON_LETTERS[letter] and 4 or 1
		for _ = 1, weight do
			bag[#bag + 1] = letter
		end
	end
	return bag
end

function M.pick_weighted_letter(bag, index)
	if not bag or #bag == 0 or not index then return nil end
	if index < 1 or index > #bag then return nil end
	return bag[index]
end

return M
