--[[ word_game/model/cards/registry.lua - Letter face/center definitions on live_game().LETTERS ]]

local live_game = require("word_game.model.live_game")

local M = {}

local shared_letters = nil

function M.ensure()
	local game = live_game()
	if not game then return nil end
	if not game.LETTERS then
		if shared_letters then
			game.LETTERS = shared_letters
		else
			game.LETTERS = {
				faces = {},
				centers = {},
				center_pools = {},
				locked = {},
			}
			shared_letters = game.LETTERS
		end
	elseif not shared_letters then
		shared_letters = game.LETTERS
	end
	return game.LETTERS
end

function M.faces()
	return live_game() and live_game().LETTERS and live_game().LETTERS.faces
end

function M.centers()
	return live_game() and live_game().LETTERS and live_game().LETTERS.centers
end

function M.center_pools()
	return live_game() and live_game().LETTERS and live_game().LETTERS.center_pools
end

function M.locked()
	return live_game() and live_game().LETTERS and live_game().LETTERS.locked
end

--- Random letter face + base center for loading wipe card art.
function M.random_wipe_card()
	local faces = M.faces()
	local centers = M.centers()
	if not faces or not centers then return nil, nil end
	return pick_random(faces), centers.letter_base
end

return M
