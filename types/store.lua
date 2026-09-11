--[[
	types/store.lua - Game store state and action type definitions (analyzer-only).
]]

---@meta

---@class GameStoreState
---@field points number
---@field round number
---@field word_round WordRoundState
---@field piles PileState
---@field run_state RunState|nil
---@field placement_word string|nil
---@field placement_word_valid boolean|nil
---@field shuffle_hand_count number|nil
---@field timeline_seconds number|nil
---@field trade_ui_busy boolean|nil
---@field last_gameplay_action string|nil
---@field last_trade_action string|nil

---@class PileState
---@field hand table[]
---@field draw table[]
---@field pattern table[]
---@field bonus table[]
---@field discard table[]

---@class GameStore
local GameStore = {}
function GameStore:get() end
function GameStore:dispatch(action) end
function GameStore:patch(patch) end
function GameStore:replace(state) end
function GameStore:subscribe(fn) end
