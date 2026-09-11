--[[
	jumbalaya-engine/settings.lua - SettingsService interface (Phase 4b).
]]

---@class SettingsService
local SettingsService = {}
SettingsService.__index = SettingsService

function SettingsService.new(adapter)
	return setmetatable({ _adapter = adapter }, SettingsService)
end

function SettingsService:queue_change(key, value)
	if self._adapter and self._adapter.queue_change then
		return self._adapter.queue_change(key, value)
	end
end

function SettingsService:apply_queued()
	if self._adapter and self._adapter.apply_queued then
		return self._adapter.apply_queued()
	end
end

return SettingsService
