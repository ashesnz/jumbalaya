--[[ word_game/model/persistence/save_schema.lua - Run snapshot schema version and load upgrades ]]

local M = {}

--- Current on-disk run snapshot schema. Bump when GAME/store fields change shape.
M.CURRENT = 1

local function game_table(snapshot)
	if type(snapshot) ~= "table" then return nil end
	local game = snapshot.GAME
	if type(game) ~= "table" then return nil end
	return game
end

--- One-time load upgrade for pre-schema saves (alpha → run_state).
local function upgrade_unversioned(game)
	if game.run_state then
		game.alpha = nil
		return true
	end
	if game.alpha then
		game.run_state = game.alpha
		game.alpha = nil
		return true
	end
	return false
end

--- Normalize a loaded snapshot in place. Returns false when the save cannot be resumed.
function M.prepare_loaded(snapshot)
	local game = game_table(snapshot)
	if not game then return false end

	local schema = snapshot.SAVE_SCHEMA
	if schema == nil then
		if not upgrade_unversioned(game) then
			return false
		end
		snapshot.SAVE_SCHEMA = M.CURRENT
		return true
	end

	if schema > M.CURRENT then
		return false
	end

	game.alpha = nil
	if not game.run_state then
		return false
	end
	snapshot.SAVE_SCHEMA = M.CURRENT
	return true
end

function M.is_loadable(snapshot)
	return M.prepare_loaded(snapshot)
end

function M.stamp_write(snapshot)
	if type(snapshot) == "table" then
		snapshot.SAVE_SCHEMA = M.CURRENT
	end
end

return M
