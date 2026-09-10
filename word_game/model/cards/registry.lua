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

--- Random letter face + base center for loading wipe card art.
function M.random_wipe_card()
	local faces = M.faces()
	local centers = M.centers()
	if not faces or not centers then return nil, nil end
	return pick_random(faces), centers.letter_base
end

return M
