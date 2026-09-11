--[[ app/bootstrap/store_boot.lua - Phase 7: instantiate store and bind WORD_GAME ]]

local store_sync = require("bridge.store_sync")

local BridgeRuntime = require("bridge.runtime")
local function g() return BridgeRuntime.game() end

local M = {}

function M.install()
	if not g() then return nil end
	local store = store_sync.new()
	store_sync.sync_from_g(store)
	if WORD_GAME and WORD_GAME._bind_store then
		WORD_GAME._bind_store(store)
	end
	return store
end

return M
