--[[ word_game/model/wildcards.lua - Consume single-use Wildcards ]]

local wild_cfg = require("word_game.config.wildcards")
local state = require("word_game.model.state")
local round = require("word_game.model.round")

local M = {}

function M.add(key)
	local alpha = state.get()
	if not alpha or not wild_cfg.get(key) then return false end
	alpha.wildcards[#alpha.wildcards + 1] = key
	return true
end

function M.use(index)
	local alpha = state.get()
	if not alpha or not alpha.wildcards[index] then
		return false, "No wildcard"
	end
	local key = table.remove(alpha.wildcards, index)
	if key == "second_wind" then
		round.add_play()
		return true, "Extra play this Hand"
	elseif key == "wild_twin" then
		alpha.wild_twin_pending = true
		return true, "Next word counts as a Twin"
	elseif key == "alphabet_soup" then
		local trade = require("word_game.model.trade")
		local ok, msg = trade.auto()
		return ok, msg
	end
	return false, "Unknown wildcard"
end

function M.consume_wild_twin()
	local alpha = state.get()
	if alpha then
		alpha.wild_twin_pending = false
	end
end

return M
