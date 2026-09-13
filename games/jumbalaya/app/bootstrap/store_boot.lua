--[[ app/bootstrap/store_boot.lua - Instantiate store and bind WORD_GAME (Phase 10d) ]]

local store_ops = require("word_game.model.store_ops")

local M = {}

function M.install()
	local word_game = package.loaded["word_game"]
	if word_game and word_game.store and word_game.store() then
		return word_game.store()
	end
	local store = store_ops.new()
	if word_game and word_game._bind_store then
		word_game._bind_store(store)
	end
	return store
end

return M
