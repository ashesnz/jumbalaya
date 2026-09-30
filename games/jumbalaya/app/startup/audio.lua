--[[ app/startup/audio.lua - Audio worker handshake and main-thread preload fallback ]]

local MIXER = require("jumbalaya-engine.sound.mixer")
local AudioInit = require("jumbalaya-engine.adapters.love2d.audio_init")
local AudioSource = require("jumbalaya-engine.adapters.love2d.audio_source")
local GameFiles = require("app.platform.game_files")

local function drain_audio_log(worker, deadline)
	while love.timer.getTime() < deadline do
		local msg = worker.log:pop()
		while msg do
			if msg == "finished" then
				return true
			end
			if type(msg) == "string" and msg:match("^error") then
				return false
			end
			msg = worker.log:pop()
		end
		if worker.thread and worker.thread.isRunning and not worker.thread:isRunning() then
			return false
		end
		love.timer.sleep(0.001)
	end
	return false
end

function Game:boot_audio()
	GameFiles.ensure_mounted()
	local paths = require("bootstrap_paths").resolve()
	AudioSource.set_asset_root(paths.game_root)

	AudioInit.warm()
	if self.AUDIO_WORKER then
		local deadline = love.timer.getTime() + 15
		self.AUDIO_WORKER.ready = drain_audio_log(self.AUDIO_WORKER, deadline)
		if not self.AUDIO_WORKER.ready then
			pcall(function()
				self.AUDIO_WORKER.channel:push({ op = "stop" })
			end)
			self.AUDIO_WORKER = nil
		end
	end

	if not (self.AUDIO_WORKER and self.AUDIO_WORKER.ready) then
		MIXER.preload(function() end)
	end
end

return true
