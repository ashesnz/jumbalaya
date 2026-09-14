--[[
	word_game/ui/play_effects/init.lua — Play-button cinematic facade (re-exports definition + animate).
	Inputs: Game shell TIMELINE, play_effects submodules.
	Outputs: resolve path via resolution.lua; queue_event, request_layout_refresh on host.
]]

local game = require("word_game.ui.util.game_runtime").game

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local definition = require("word_game.ui.play_effects.definition")
local animate = require("word_game.ui.play_effects.animate")

local M = {}

animate.bind_host(M)

local function has_event_manager()
	return game().TIMELINE and game().TIMELINE.enqueue
end

function M.queue_event(ev)
	if has_event_manager() then
		Scheduler.add{event = ev}
	elseif ev and ev.func then
		ev.func()
	end
end

function M.request_layout_refresh()
	game().ARGS = game().ARGS or {}
	game().ARGS.pending_layout = true
end

for k, v in pairs(definition) do
	M[k] = v
end

for k, v in pairs(animate) do
	M[k] = v
end

return M
