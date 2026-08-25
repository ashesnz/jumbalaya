--[[
	app/core/audio/mixer.lua - the mixing engine behind both audio runtimes.

	Runs identically inside the love.thread worker (manager.lua) and inline on
	the main thread when threading is off. Owns the source pool as module
	state, so neither runtime duplicates pooling or mixing logic.

	Every entry in the pool looks like:
	  sound        love.audio source
	  code         sound name (filename minus extension)
	  base_rate    pitch multiplier requested at play time
	  base_gain    volume multiplier requested at play time
	  fade_level   music crossfade position (0..1), music entries only
	  born_paused  started while an overlay was up
	  state_tag    game state the sound was triggered from

	Requests are plain records; `settings` always carries G.SETTINGS.SOUND.
]]

local MIXER = {}

local SPLASH_STATE_ID = 13

-- Music codes: exact names plus anything mentioning "music".
local MUSIC_CODES = {title = true, gameplay = true}

--- Buckets a sound code into 'music', 'bed' (streamed ambient layer) or 'sfx'.
function MIXER.classify(code)
	if not code then return 'sfx' end
	local lower = string.lower(code)
	if MUSIC_CODES[lower] or string.find(lower, 'music', 1, true) then return 'music' end
	if string.find(lower, 'ambient', 1, true) then return 'bed' end
	return 'sfx'
end

local pool = {}

-- Headless/test environments may lack a real audio backend; every entry
-- point degrades to a no-op there.
local function audio_available()
	return love and love.audio and love.audio.newSource
end

--- Creates a decoded source, or nil when the file is missing/unreadable
--- (e.g. an asset that was culled but is still requested by game code).
local function load_source(code, kind)
	local ok, source = pcall(love.audio.newSource,
		"resources/sounds/" .. code .. '.ogg',
		(kind ~= 'sfx') and "stream" or "static")
	return ok and source or nil
end

local function new_source(code, kind)
	return load_source(code, kind)
end

--- Warms every .ogg under resources/sounds through its decoder so first-play
--- hitches disappear. `log` receives progress lines for the loading screen.
function MIXER.preload(log)
	for _, filename in ipairs(love.filesystem.getDirectoryItems("resources/sounds")) do
		if string.sub(filename, -4) == '.ogg' then
			log('audio file - ' .. filename)
			local code = string.sub(filename, 1, -5)
			local kind = MIXER.classify(code)
			local sound = load_source(code, kind)
			if not sound then
				log('audio file skipped - ' .. filename)
			else
				local entry = {
					sound = sound,
					code = code,
					base_rate = 1,
					base_gain = 1,
				}
				if kind == 'music' then entry.sound:setLooping(true) end
				pool[code] = {entry}
				entry.sound:setVolume(0)
				love.audio.play(entry.sound)
				entry.sound:stop()
			end
		end
	end
end

--- Starts a sound. With `recycle`, idle pooled sources are reused before a
--- fresh source is created; music always loops, music and beds stream.
---@return table the live entry (a dummy when no audio backend exists)
function MIXER.play(req, recycle)
	if not audio_available() then return {sound = nil} end
	local kind = MIXER.classify(req.code)
	pool[req.code] = pool[req.code] or {}

	if recycle then
		for _, entry in ipairs(pool[req.code]) do
			if entry.sound and not entry.sound:isPlaying() then
				entry.base_rate = req.rate or 1
				entry.base_gain = req.gain or 1
				entry.born_paused = not (not req.in_overlay)
				entry.state_tag = req.state_tag
				MIXER.apply(entry, req)
				love.audio.play(entry.sound)
				return entry
			end
		end
	end

	local entry = {
		sound = new_source(req.code, kind),
		code = req.code,
		base_rate = req.rate or 1,
		base_gain = req.gain or 1,
		born_paused = not (not req.in_overlay),
		state_tag = req.state_tag,
	}
	if not entry.sound then
		-- Missing asset: return a silent dummy so callers can proceed.
		pool[req.code] = pool[req.code] or {}
		return entry
	end
	if kind == 'music' then entry.sound:setLooping(true) end
	table.insert(pool[req.code], entry)
	MIXER.apply(entry, req)
	love.audio.play(entry.sound)
	return entry
end

--- Halts every source on the spot.
function MIXER.stop_all()
	for _, entries in pairs(pool) do
		for _, entry in ipairs(entries) do
			if entry.sound and entry.sound:isPlaying() then entry.sound:stop() end
		end
	end
end

--- Applies current settings to one source. Music crossfades toward/away from
--- the desired track (time constant ~dt*3); SFX hold static volume with a
--- splash-state duck and release their voice when silenced.
function MIXER.apply(entry, req)
	if not entry.sound or not audio_available() then return end
	local settings = req.settings
	local kind = MIXER.classify(entry.code)

	if kind == 'music' then
		entry.fade_level = entry.fade_level or 0
		local target = (entry.code == req.track) and 1 or 0
		local blend = (req.dt or 0) * 3
		entry.fade_level = target * blend + (1 - blend) * entry.fade_level
		entry.sound:setVolume(entry.fade_level * entry.base_gain
			* (settings.volume / 100.0) * (settings.music_volume / 100.0))
		entry.sound:setPitch(entry.base_rate * (req.pitch_mod or 1))
		-- Fully faded non-desired tracks pause to free a mixer voice.
		if entry.fade_level <= 0.001 and entry.code ~= req.track and entry.sound:isPlaying() then
			entry.sound:pause()
		end
	else
		-- Pitch only changes when asked; avoid touching it every frame.
		if entry.applied_rate ~= entry.base_rate then
			entry.sound:setPitch(entry.base_rate)
			entry.applied_rate = entry.base_rate
		end
		local gain = entry.base_gain
			* (settings.volume / 100.0)
			* (settings.game_sounds_volume / 100.0)
		if entry.state_tag == SPLASH_STATE_ID then gain = gain * (req.splash_gain or 1) end
		if gain <= 0 then
			entry.sound:stop()
		else
			entry.sound:setVolume(gain)
		end
	end
end

--- Keeps the desired track alive, retires finished SFX sources (freeing
--- memory), and refreshes volumes/pitches of everything still live.
function MIXER.refresh(req)
	if req.track and req.track ~= '' then
		local entries = pool[req.track]
		if not entries or #entries == 0 then
			req.op = 'play'
			req.code = req.track
			req.rate = 1
			req.gain = 1
			MIXER.play(req, false)
		else
			local lead = entries[1]
			if lead and lead.sound and not lead.sound:isPlaying() then
				lead.sound:play()
			end
		end
	end

	for code, entries in pairs(pool) do
		-- Retire finished SFX entirely (music stays pooled).
		local i = 1
		while i <= #entries do
			local entry = entries[i]
			if entry.sound and not entry.sound:isPlaying() and MIXER.classify(code) == 'sfx' then
				if entry.sound.release then entry.sound:release() end
				table.remove(entries, i)
			else
				i = i + 1
			end
		end

		for _, entry in ipairs(entries) do
			if entry.sound then MIXER.apply(entry, req) end
		end
	end
end

--- Stops and recreates every music source with fresh decoders.
function MIXER.replay_music(req)
	for code, entries in pairs(pool) do
		if MIXER.classify(code) == 'music' then
			for _, entry in ipairs(entries) do entry.sound:stop() end
			pool[code] = {}
			req.op = 'play'
			req.code = code
			req.rate = 1
			req.gain = 1
			MIXER.play(req, false)
		end
	end
end

--- Keeps the configured bed layers playing at requested volumes/rates;
--- starts any layer that has no live source yet (and audible settings allow).
function MIXER.sync_beds(req)
	for code, entries in pairs(pool) do
		local control = req.beds[code]
		if control then
			local needs_start = control.gain * (req.settings.volume / 100.0)
				* (req.settings.game_sounds_volume / 100.0) > 0

			for _, entry in ipairs(entries) do
				if entry.sound and entry.sound:isPlaying() then
					entry.base_gain = control.gain
					MIXER.apply(entry, req)
					needs_start = false
				end
			end

			if needs_start then
				MIXER.play({code = code, rate = control.rate, gain = control.gain,
					settings = req.settings}, false)
			end
		end
	end
end

--- Re-tags every live source with a new game state (e.g. back to menu).
function MIXER.retag(state_tag)
	for _, entries in pairs(pool) do
		for _, entry in ipairs(entries) do
			entry.state_tag = state_tag
		end
	end
end

return MIXER
