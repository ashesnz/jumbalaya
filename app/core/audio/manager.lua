--[[
	app/core/audio/manager.lua - audio worker thread.

	Runs as a love.thread (started from app/startup.lua when
	`G.F_SOUND_THREAD` is on). Preloads every .ogg under resources/sounds,
	reports progress over the 'alpha_audio_log' channel, then serves requests
	from 'alpha_audio_in' forever. All pooling/mixing lives in the shared
	mixer module; this file is just the transport loop.

	Request records:
	  {op='play', code=..., rate=, gain=, settings=, ...}  start a sound
	  {op='mix', dt=, track=, beds=?, settings=, ...}      per-frame mix update
	  {op='stop'}                                          halt everything
	  {op='music', settings=...}           stop + restart all music tracks
	  {op='retag', state_tag=}             retag live sources with a new state
]]

require "love.audio"
require "love.sound"
require "love.system"

if love.system.getOS() == 'OS X' then jit.off() end

local MIXER = require("app.core.audio.mixer")

local log_channel = love.thread.getChannel('alpha_audio_log')
local inbound = love.thread.getChannel('alpha_audio_in')

log_channel:push('audio thread start')
MIXER.preload(function(message) log_channel:push(message) end)
log_channel:push('finished')

local HANDLERS = {
	play = function(req) MIXER.play(req, true) end,
	stop = MIXER.stop_all,
	mix = function(req)
		MIXER.refresh(req)
		if req.beds then MIXER.sync_beds(req) end
	end,
	music = MIXER.replay_music,
	retag = function(req) MIXER.retag(req.state_tag) end,
}

while true do
	local req = inbound:demand()
	if req then
		local handler = HANDLERS[req.op]
		if handler then handler(req) end
	end
end
