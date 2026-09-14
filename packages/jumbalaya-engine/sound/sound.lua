--[[
	app/core/audio/sound.lua - main-thread audio API.

	`play_sfx` is fire-and-forget; `mix_audio` runs every frame to steer the
	music track, bed intensity, and global pitch. When the worker thread is on
	these build request records and push them across the channel; otherwise
	they call the shared mixer directly.
]]

local MIXER = require("jumbalaya-engine.sound.mixer")
local shell = require("jumbalaya-engine.shell")
local game = shell.game

-- Reused request records: keeps per-frame allocation at zero.
local play_request, mix_request, retag_request = {}, {}, {}

--- Re-tags every live source with a new game state (e.g. back to the menu),
--- so splash ducking and pause behaviour follow along.
function retag_audio(state_tag)
	if game().F_SOUND_THREAD then
		if game().AUDIO_WORKER and game().AUDIO_WORKER.channel then
			retag_request.op = 'retag'
			retag_request.state_tag = state_tag
			game().AUDIO_WORKER.channel:push(retag_request)
		end
	else
		MIXER.retag(state_tag)
	end
end

--- Fire-and-forget SFX request; silently no-ops when muted or volume is zero.
function play_sfx(code, rate, gain)
	if game().F_MUTE then return end
	if not (code and not game().muted and game().SETTINGS.SOUND.volume > 0) then return end

	local req = play_request
	req.op = 'play'
	req.code = code
	req.rate = rate
	req.gain = gain
	req.pitch_mod = game().PITCH_MOD
	req.state_tag = game().STATE
	req.settings = game().SETTINGS.SOUND
	req.splash_gain = game().SPLASH_VOL
	req.in_overlay = not (not game().OVERLAY_MENU)

	if game().F_SOUND_THREAD then
		if game().AUDIO_WORKER and game().AUDIO_WORKER.channel then
			game().AUDIO_WORKER.channel:push(req)
		end
	else
		MIXER.play(req, false)
	end
end

--- Per-frame mix update. Chooses the desired music track, tracks score-driven
--- bed intensity, relaxes global pitch back to normal, and dispatches.
function mix_audio(dt)
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
	game().ARGS.score_intensity = game().ARGS.score_intensity or {}
	local wr = shell.word_round()
	local earned = 0
	if wr and wr.jumble then
		local j = wr.jumble
		earned = (j.total_score or 0) + math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1.0))
	end
	game().ARGS.score_intensity.earned_score = earned
	game().ARGS.score_intensity.required_score = (wr and wr.target) or 0
	local intensity = game().ARGS.score_intensity
	intensity.flames = math.min(1, (game().STAGE == game().STAGES.RUN and 1 or 0) *
		((game().ARGS.chip_flames and (game().ARGS.chip_flames.real_intensity + game().ARGS.chip_flames.change)) or 0) / 10)
	intensity.organ = game().video_organ or (intensity.required_score > 0
		and math.max(math.min(0.4, 0.1 * math.log(intensity.earned_score / (intensity.required_score + 1), 5)), 0))
		or 0

	-- Bed layer targets ease toward their intensity-derived levels.
	local beds = game().SETTINGS.ambient_control
	game().ARGS.ambient_sounds = game().ARGS.ambient_sounds or {
		-- Base fire bed once flames pass 30%.
		ambientFire2 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.9 * ((intensity.flames > 0.3) and 1 or intensity.flames / 0.3) end},
		-- High-intensity fire layer joins above 30%.
		ambientFire1 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.8 * ((intensity.flames > 0.3) and (intensity.flames - 0.3) / 0.7 or 0) end},
		-- Crackling reacts directly to chip/mult flame changes.
		ambientFire3 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.4 * ((game().ARGS.chip_flames and game().ARGS.chip_flames.change or 0) + (game().ARGS.mult_flames and game().ARGS.mult_flames.change or 0)) end},
		-- Organ swells logarithmically with earned-vs-target score.
		ambientOrgan1 = {gainfunc = function(prev) return prev * (1 - dt) + dt * 0.6 * (game().SETTINGS.SOUND.music_volume + 100) / 200 * intensity.organ end},
	}

	for name, layer in pairs(game().ARGS.ambient_sounds) do
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
	req.settings = game().SETTINGS.SOUND
	req.splash_gain = game().SPLASH_VOL
	req.in_overlay = not (not game().OVERLAY_MENU)

	if game().F_SOUND_THREAD then
		if game().AUDIO_WORKER and game().AUDIO_WORKER.channel then
			game().AUDIO_WORKER.channel:push(req)
		end
	else
		MIXER.refresh(req)
		MIXER.sync_beds(req)
	end
end
