--[[
	jumbalaya-engine/audio.lua - AudioService interface and Love2D adapter.
]]

---@class AudioService
local AudioService = {}
AudioService.__index = AudioService

local DEFAULT_SFX = {
	PLAY_WORD = "card1",
	ROUND_RECORD_WORD = "card1",
	RUN_MATCH_END = "negative",
	HAND_CLEARED = "coin2",
}

function AudioService.new(opts)
	opts = opts or {}
	return setmetatable({
		_sfx_map = opts.sfx_map or DEFAULT_SFX,
		_bound_store = nil,
	}, AudioService)
end

function AudioService:play(id, opts)
	opts = opts or {}
	if type(play_sfx) == "function" then
		play_sfx(id, opts.rate, opts.gain)
	end
end

function AudioService:on_action(action)
	if not action or not action.type then return end
	local id = self._sfx_map[action.type]
	if id then
		self:play(id, { rate = 1, gain = 0.6 })
	end
end

function AudioService:bind_store(store)
	if not store or self._bound_store == store then return end
	self._bound_store = store
	local audio = self
	local base_dispatch = store.dispatch
	store.dispatch = function(self_store, action)
		local state = base_dispatch(self_store, action)
		audio:on_action(action)
		return state
	end
end

return AudioService
