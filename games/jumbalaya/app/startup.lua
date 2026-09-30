--[[
	app/startup.lua - Application boot orchestration.

	Game:launch() is the entry after Game:construct() / define_constants().
]]

local boot_stage = require("jumbalaya-engine.adapters.love2d.display").boot_stage
local StartupAssets = require "app.startup.assets"
require "app.startup.menu_boot"
require "app.startup.profile"
require "app.startup.window"
require "app.startup.dealing"
require "app.startup.audio"

function Game:launch()
	local settings = read_game_save('settings')
	local settings_ver = nil
	if settings then
		local settings_file = unpack_source(settings)
		if self.VERSION >= '1.0.0' and (love.system.getOS() == 'Windows') and ((not settings_file.version) or (settings_file.version < '1.0.0')) then
			for i = 1, 3 do
				love.filesystem.remove(i .. '/profile.jmb')
				love.filesystem.remove(i .. '/profile.acs')
				love.filesystem.remove(i .. '/save.jmb')
				love.filesystem.remove(i .. '/save.acs')
				love.filesystem.remove(i .. '/meta.jmb')
				love.filesystem.remove(i .. '/meta.acs')
				love.filesystem.remove(i..'')
			end
			for k, v in pairs(settings_file) do
				self.SETTINGS[k] = v
			end
			self.SETTINGS.profile = 1
		else
			if self.VERSION < '1.0.0' then
				settings_ver = settings_file.version
			end
			for k, v in pairs(settings_file) do
				self.SETTINGS[k] = v
			end
		end
	end
	self.SETTINGS.version = settings_ver or self.VERSION
	self.SETTINGS.paused = nil

	if type(self.SETTINGS.SOUND) ~= 'table' then
		self.SETTINGS.SOUND = {}
	end
	local sound = self.SETTINGS.SOUND
	if type(self.SETTINGS.screenshake) ~= 'number' then
		self.SETTINGS.screenshake = 50
	end
	sound.volume = tonumber(sound.volume) or 100
	sound.music_volume = tonumber(sound.music_volume) or 100
	sound.game_sounds_volume = tonumber(sound.game_sounds_volume) or 100
	if sound.volume == 0 and sound.music_volume == 0 and sound.game_sounds_volume == 0 then
		sound.volume = 100
		sound.music_volume = 100
		sound.game_sounds_volume = 100
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

	local audio_worker_script = (love.filesystem.getInfo and love.filesystem.getInfo("app/sound/worker.lua") and "app/sound/worker.lua")
		or (love.filesystem.getInfo and love.filesystem.getInfo("../../packages/jumbalaya-engine/sound/manager.lua") and "../../packages/jumbalaya-engine/sound/manager.lua")
	if self.F_SOUND_THREAD and audio_worker_script then
		boot_stage('window init', 'audio worker')
		self.AUDIO_WORKER = {
			thread = love.thread.newThread(audio_worker_script),
			channel = love.thread.getChannel('alpha_audio_in'),
			log = love.thread.getChannel('alpha_audio_log'),
		}
		self.AUDIO_WORKER.thread:start(1)

		boot_stage('audio worker', 'save worker', 0.22)
	end
	self:boot_audio()

	boot_stage('window init', 'save worker')
	if love.thread and love.thread.newThread and (not love.filesystem.getInfo or love.filesystem.getInfo('app/persistence/worker.lua')) then
		local thread_ok, thread_res = pcall(love.thread.newThread, 'app/persistence/worker.lua')
		if thread_ok and thread_res then
			self.DISK_WORKER = {
				thread = thread_res,
				channel = love.thread.getChannel('disk_write_queue')
			}
			self.DISK_WORKER.thread:start(2)
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

	self:load_profile(self.SETTINGS.profile or 1)

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
