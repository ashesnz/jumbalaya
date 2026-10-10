--[[
	jumbalaya-engine/sound/sound.lua - main-thread audio API.

	`play_sfx` is fire-and-forget; `mix_audio` runs every frame to steer the
	music track, bed intensity, and global pitch. When the worker thread is on
	these build request records and push them across the channel; otherwise
	they call the shared mixer directly.
]]

local MIXER = require("jumbalaya-engine.sound.mixer")
local shell = require("jumbalaya-engine.shell")
local game = shell.game

local M = {}

local function sound_settings_snapshot(sound)
	if not sound then return sound end
	return {
		volume = tonumber(sound.volume) or 0,
		music_volume = tonumber(sound.music_volume) or 0,
		game_sounds_volume = tonumber(sound.game_sounds_volume) or 0,
	}
end

-- Reused request records: keeps per-frame allocation at zero.
local play_request, mix_request, retag_request = {}, {}, {}

--- True only when the audio worker is actually serving the mix channel.
--- `F_SOUND_THREAD` alone is not enough: the worker script lives outside the
--- Love source tree, so it often never starts — dropping every play/mix.
local function audio_thread_live()
	local g = game()
	if not g or not g.F_SOUND_THREAD then
		return false
	end
	local worker = g.AUDIO_WORKER
	if not (worker and worker.channel) then
		return false
	end
	if worker.thread and worker.thread.isRunning and not worker.thread:isRunning() then
		return false
	end
	if worker.ready ~= true then
		return false
	end
	return true
end

M.audio_thread_live = audio_thread_live

--- Re-tags every live source with a new game state (e.g. back to the menu),
--- so splash ducking and pause behaviour follow along.
function M.retag_audio(state_tag)
	if audio_thread_live() then
		retag_request.op = 'retag'
		retag_request.state_tag = state_tag
		game().AUDIO_WORKER.channel:push(retag_request)
	else
		MIXER.retag(state_tag)
	end
end

--- Fire-and-forget SFX request; silently no-ops when muted or volume is zero.
function M.play_sfx(code, rate, gain)
	if game().F_MUTE then return end
	local settings = game().SETTINGS
	local master = settings and settings.SOUND and tonumber(settings.SOUND.volume) or 0
	if not (code and not game().muted and master > 0) then return end

	local req = play_request
	req.op = 'play'
	req.code = code
	req.rate = rate
	req.gain = gain
	req.pitch_mod = game().PITCH_MOD
	req.state_tag = game().STATE
	req.settings = sound_settings_snapshot(settings.SOUND)
	req.splash_gain = game().SPLASH_VOL
	req.in_overlay = not (not game().OVERLAY_MENU)

	if audio_thread_live() then
		game().AUDIO_WORKER.channel:push(req)
	else
		MIXER.play(req, false)
	end
end

--- Per-frame mix update. Chooses the desired music track, tracks score-driven
--- bed intensity, relaxes global pitch back to normal, and dispatches.
function M.mix_audio(dt)
	if not (game() and game().SETTINGS and game().SETTINGS.SOUND) then
		return
	end
	-- Splash screen fades its own layer in/out via this decaying gate.
	game().SPLASH_VOL = 2 * dt * (game().STATE == game().STATES.SPLASH and 1 or 0) + (game().SPLASH_VOL or 1) * (1 - 2 * dt)

	local desired_track =
		game().video_soundtrack or
		((game().STAGE == game().STAGES.RUN) and 'Gameplay') or
		'Title'

	-- Global pitch relaxes back to normal; sags on the game-over screen.
	game().PITCH_MOD = (game().PITCH_MOD or 1) * (1 - dt)
		+ dt * ((not game().normal_music_speed and game().STATE == game().STATES.GAME_OVER) and 0.5 or 1)

	-- Score intensity feeds the ambient fire/organ beds.
	game().SETTINGS.ambient_control = game().SETTINGS.ambient_control or {}
	game().score_intensity = game().score_intensity or {}
	local wr = shell.word_round()
	local earned = 0
	if wr and wr.jumble then
		local j = wr.jumble
		earned = (j.total_score or 0) + math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1.0))
	end
	game().score_intensity.earned_score = earned
	game().score_intensity.required_score = (wr and wr.target) or 0
	local intensity = game().score_intensity
	local run_live = (game().STAGE == game().STAGES.RUN) and 1 or 0
	local score_ratio = (intensity.required_score > 0)
		and math.min(1, intensity.earned_score / (intensity.required_score + 1))
		or 0
	intensity.flames = run_live * score_ratio
	intensity.organ = game().video_organ or (intensity.required_score > 0
		and math.max(math.min(0.4, 0.1 * math.log(intensity.earned_score / (intensity.required_score + 1), 5)), 0))
		or 0

	-- Bed layer targets ease toward their intensity-derived levels.
	local beds = game().SETTINGS.ambient_control
	game().ambient_sounds = game().ambient_sounds or {
		-- Base fire bed once flames pass 30%.
		ambientFire2 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.9 * ((intensity.flames > 0.3) and 1 or intensity.flames / 0.3) end},
		-- High-intensity fire layer joins above 30%.
		ambientFire1 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.8 * ((intensity.flames > 0.3) and (intensity.flames - 0.3) / 0.7 or 0) end},
		-- Crackling tracks score intensity.
		ambientFire3 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.4 * intensity.flames end},
		-- Organ swells logarithmically with earned-vs-target score.
		ambientOrgan1 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.6 * (game().SETTINGS.SOUND.music_volume + 100) / 200 * intensity.organ end},
	}

	for name, layer in pairs(game().ambient_sounds) do
		beds[name] = beds[name] or {}
		beds[name].rate =
			(name == 'ambientOrgan1' and 0.7) or
			(name == 'ambientFire1' and 1.1) or
			(name == 'ambientFire2' and 1.05) or 1
		beds[name].gain =
			((not game().video_organ) and game().STATE == game().STATES.SPLASH) and 0
			or (beds[name].gain and layer.gainfunc(beds[name].gain)) or 0
	end

	local req = mix_request
	req.op = 'mix'
	req.dt = dt
	req.track = desired_track
	req.beds = beds
	req.pitch_mod = game().PITCH_MOD
	req.state_tag = game().STATE
	req.settings = sound_settings_snapshot(game().SETTINGS.SOUND)
	req.splash_gain = game().SPLASH_VOL
	req.in_overlay = not (not game().OVERLAY_MENU)

	if audio_thread_live() then
		game().AUDIO_WORKER.channel:push(req)
	else
		MIXER.refresh(req)
		MIXER.sync_beds(req)
	end
end

return M
