--[[
	types/store.lua - Game store state and action type definitions (analyzer-only).
]]

---@meta

---@class GameStoreState
---@field points number
---@field round number
---@field word_round table
---@field piles table
---@field run RunState|nil

---@class GameStore
local GameStore = {}
function GameStore:get() end
function GameStore:dispatch(action) end
function GameStore:patch(patch) end
function GameStore:replace(state) end
function GameStore:subscribe(fn) end
