--[[ word_game/model/cards/registry.lua - Letter face/center definitions on G.LETTERS ]]

local M = {}

function M.ensure()
	if not G then return nil end
	if not G.LETTERS then
		G.LETTERS = {
			faces = {},
			centers = {},
			center_pools = {},
			locked = {},
		}
	end
	return G.LETTERS
end

function M.faces()
	return G and G.LETTERS and G.LETTERS.faces
end

function M.centers()
	return G and G.LETTERS and G.LETTERS.centers
end

function M.center_pools()
	return G and G.LETTERS and G.LETTERS.center_pools
end

function M.locked()
	return G and G.LETTERS and G.LETTERS.locked
end

return M
