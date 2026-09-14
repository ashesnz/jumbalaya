--[[ word_game/ui/play_effects/animate/context.lua - Shared host binding for play FX ]]

local M = {}

local host

function M.bind_host(mod)
	host = mod
end

function M.effects()
	return host
end

return M
