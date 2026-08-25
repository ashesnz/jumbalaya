--[[
	app/startup.lua - Application boot orchestration.

	Game:launch() is the entry after Game:construct() / define_constants().
]]

local StartupAssets = require "app.startup.assets"
require "app.startup.menu_boot"
require "app.startup.profile"
require "app.startup.window"
require "app.startup.dealing"

function Game:launch()
	local settings = read_save_payload('settings.acs')
	local settings_ver = nil
	if settings then
		local settings_file = unpack_source(settings)
		if G.VERSION >= '1.0.0' and (love.system.getOS() == 'Windows') and ((not settings_file.version) or (settings_file.version < '1.0.0')) then
			for i = 1, 3 do
				love.filesystem.remove(i..'/'..'profile.acs')
				love.filesystem.remove(i..'/'..'save.acs')
				love.filesystem.remove(i..'/'..'meta.acs')
				love.filesystem.remove(i..'')
			end
			for k, v in pairs(settings_file) do
				self.SETTINGS[k] = v
			end
			self.SETTINGS.profile = 1
			self.SETTINGS.tutorial_progress = nil
		else
			if G.VERSION < '1.0.0' then
				settings_ver = settings_file.version
			end
			for k, v in pairs(settings_file) do
				self.SETTINGS[k] = v
			end
		end
	end
	self.SETTINGS.version = settings_ver or G.VERSION
	self.SETTINGS.paused = nil

	local sound = self.SETTINGS.SOUND or {}
	self.SETTINGS.SOUND = sound
	if (sound.volume or 0) == 0 and (sound.game_sounds_volume or 0) == 0 then
		sound.volume = 50
		sound.game_sounds_volume = 100
	end
	if not sound.music_volume or sound.music_volume == 0 then
		sound.music_volume = 60
	end

	boot_stage('start', 'settings', 0.1)

	if self.SETTINGS.GRAPHICS.texture_scaling then
		self.SETTINGS.GRAPHICS.texture_scaling = self.SETTINGS.GRAPHICS.texture_scaling > 1 and 2 or 1
	end

	self.SETTINGS.DEMO = self.SETTINGS.DEMO or {
		total_uptime = 0,
		timed_CTA_shown = false,
		win_CTA_shown = false,
		quit_CTA_shown = false
	}

	self.SETTINGS.language = self.SETTINGS.language or 'en-us'
	boot_stage('settings', 'window init', 0.2)
	self:init_window()

	if G.F_SOUND_THREAD and love.filesystem and love.filesystem.getInfo
		and love.filesystem.getInfo('app/core/audio/manager.lua') then
		boot_stage('window init', 'audio worker')
		self.AUDIO_WORKER = {
			thread = love.thread.newThread('app/core/audio/manager.lua'),
			channel = love.thread.getChannel('alpha_audio_in'),
			log = love.thread.getChannel('alpha_audio_log'),
		}
		self.AUDIO_WORKER.thread:start(1)

		boot_stage('audio worker', 'save worker', 0.22)
	end

	boot_stage('window init', 'save worker')
	if love.thread and love.thread.newThread and (not love.filesystem.getInfo or love.filesystem.getInfo('app/core/persistence/worker.lua')) then
		local thread_ok, thread_res = pcall(love.thread.newThread, 'app/core/persistence/worker.lua')
		if thread_ok and thread_res then
			G.DISK_WORKER = {
				thread = thread_res,
				channel = love.thread.getChannel('disk_write_queue')
			}
			G.DISK_WORKER.thread:start(2)
		end
	end
	boot_stage('save worker', 'shaders',0.4)

	StartupAssets.load_shaders(self)

	boot_stage('shaders', 'controllers',0.7)

	self.INPUT = InputController()
	if love.joystick and love.joystick.loadGamepadMappings and love.filesystem.getInfo and love.filesystem.getInfo("resources/gamecontrollerdb.txt") then
		pcall(love.joystick.loadGamepadMappings, "resources/gamecontrollerdb.txt")
	end
	if self.F_RUMBLE then
		local joysticks = love.joystick and love.joystick.getJoysticks and love.joystick.getJoysticks()
		if joysticks then
			if joysticks[1] then
				self.INPUT:set_gamepad(joysticks[2] or joysticks[1])
			end
		end
	end
	boot_stage('controllers', 'localization',0.8)

	if self.SETTINGS.GRAPHICS.texture_scaling then
		self.SETTINGS.GRAPHICS.texture_scaling = self.SETTINGS.GRAPHICS.texture_scaling > 1 and 2 or 1
	end

	self:load_profile(G.SETTINGS.profile or 1)

	self.SETTINGS.QUEUED_CHANGE = {}
	self.SETTINGS.music_control = {desired_track = '', current_track = '', lerp = 1}

	self:set_render_settings()

	self:set_language()

	self:load_card_definitions()
	boot_stage('protos', 'shared sprites',0.9)

	StartupAssets.init_shared_sprites(self)
	boot_stage('shared sprites', 'prep stage',0.95)

	self:boot_initial_screen()
end
