--[[ word_game/ui/menu/animate.lua - Title garden pan and main menu open lifecycle ]]

local facade = require("word_game.ui.facade")
local Back = facade.back()
local game_access = facade.game_access()
local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Layout = require "word_game.ui.layout"
local Easing = require "word_game.ui.effects.easing"
local MenuEffects = require "word_game.ui.effects.menu"
local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local UIViewHost = require("jumbalaya-engine.panels.view_host")

require "word_game.ui.menu.title_logo"
local Funcs = require("app.callbacks.funcs")

local M = {}

local TITLE_GARDEN_MOSS = {0.12, 0.24, 0.14, 1}
local TITLE_GARDEN_EXTRA_W = 60
local TITLE_GARDEN_EXTRA_H = 22
local TITLE_GARDEN_PAN = {
	amp_x = 10,
	amp_y = 4.5,
	period_x = 48,
	period_y = 64,
}

function M.title_garden_sprite_dims(room)
	room = room or (runtime().ROOM and runtime().ROOM.T) or { w = 20, h = 11 }
	return (room.w or 20) + TITLE_GARDEN_EXTRA_W, (room.h or 11) + TITLE_GARDEN_EXTRA_H
end

function M.title_garden_pan_offset(time)
	time = time or 0
	local pan = TITLE_GARDEN_PAN
	local x = math.sin(time * 2 * math.pi / pan.period_x) * pan.amp_x
	local y = math.sin(time * 2 * math.pi / pan.period_y) * pan.amp_y
	return x, y
end

function M.update_title_garden_pan(dt)
	local sprite = runtime().SPLASH_BACK
	local pan = sprite and sprite.title_garden_pan
	if type(pan) ~= "table" then return end
	local off = sprite.alignment and sprite.alignment.offset
	if not off then return end
	dt = dt or (runtime() and runtime().real_dt) or 0
	pan.t = (pan.t or 0) + dt
	off.x, off.y = M.title_garden_pan_offset(pan.t)
end

local function setup_title_garden_background()
	if runtime().SPLASH_BACK then
		runtime().SPLASH_BACK:remove()
		runtime().SPLASH_BACK = nil
	end

	local atlas = runtime().TEXTURE_ATLASES and runtime().TEXTURE_ATLASES.title_garden
	if not atlas or not atlas.image then return end

	local w, h = M.title_garden_sprite_dims()
	runtime().SPLASH_BACK = Sprite(-30, -13, w, h, atlas, {x = 0, y = 0})
	runtime().SPLASH_BACK:set_alignment({
		major = runtime().ROOM_ATTACH,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})
	runtime().SPLASH_BACK.title_garden_pan = { t = 0 }
end

function M.open_main_menu(self, change_context)
	if change_context ~= "splash" then
		runtime().TIMERS.REAL = 12
		runtime().TIMERS.TOTAL = 12
	else
		retag_audio(runtime().STATES.MENU)
	end

	self:prep_stage(runtime().STAGES.MAIN_MENU, runtime().STATES.MENU, true)
	game_access.patch({
		selected_back = Back.new(runtime().LETTERS.centers.deck_alpha),
	})

	if Funcs.get("change_shadows") and runtime().SETTINGS and runtime().SETTINGS.GRAPHICS then
		Funcs.dispatch("change_shadows", {to_key = runtime().SETTINGS.GRAPHICS.shadows == "On" and 1 or 2})
	end
	Easing.background_colour{new_colour = TITLE_GARDEN_MOSS, contrast = 1}
	if runtime().SPLASH_FRONT then runtime().SPLASH_FRONT:remove(); runtime().SPLASH_FRONT = nil end
	setup_title_garden_background()

	Scheduler.add{mode = "instant", func = function()
		return true
	end}

	local scale = 1.1 * (runtime().debug_splash_size_toggle and 0.8 or 1)
	self.title_top = CardPile(0, 0, runtime().CARD_W, runtime().CARD_H, {card_limit = 1, type = "title"})
	local logo_atlas = runtime().TEXTURE_ATLASES and runtime().TEXTURE_ATLASES.jumbalaya_base
	local logo_ratio = logo_atlas and logo_atlas.py and logo_atlas.px
		and logo_atlas.py / logo_atlas.px or (267 / 933)
	local logo_w, logo_h = 13 * scale, 13 * scale * logo_ratio
	if logo_atlas and runtime().TEXTURE_ATLASES.jumbalaya_start_a and runtime().TEXTURE_ATLASES.jumbalaya_end_a then
		runtime().SPLASH_LOGO = TitleLogo.create(self.title_top, logo_w, logo_h)
	else
		runtime().SPLASH_LOGO = Sprite(0, 0, logo_w, logo_h, logo_atlas, {x = 0, y = 0})
		runtime().SPLASH_LOGO:set_alignment({major = self.title_top, type = "cm", bond = "Strong", offset = {x = 0, y = 0}})
		runtime().SPLASH_LOGO:define_draw_steps({{shader = "dissolve"}})
	end
	runtime().SPLASH_LOGO.dissolve_colours = {runtime().C.WHITE, runtime().C.WHITE}
	runtime().SPLASH_LOGO.dissolve = 1

	Scheduler.add{mode = "delayed",
		delay = change_context == "splash" and 1.8 or change_context == "game" and 2 or 0.15,
		blockable = false, blocking = false, func = function()
		local crumple_variant = change_context == "splash" and 2 or 3
		if play_sfx then
			play_sfx("magic_crumple" .. crumple_variant, change_context == "splash" and 0.95 or 1.25, 0.85)
			play_sfx("whoosh1", 0.55, 0.7)
		end
			if runtime().SPLASH_LOGO then Easing.value{ref_table = runtime().SPLASH_LOGO, ref_value = "dissolve", mod = -1, delay = change_context == "splash" and 2.3 or 0.9} end
			if runtime().VIBRATION then runtime().VIBRATION = runtime().VIBRATION + 1.5 end
			return true
		end}
	Scheduler.delayed{delay = 0.1 + (change_context == "splash" and 2 or change_context == "game" and 1.5 or 0)}
	Scheduler.add{func = function() if runtime().INPUT then runtime().INPUT.lock_input = false end; return true end}
	Layout.set_screen_positions()
	self.title_top:sort("order")
	self.title_top:set_ranks()
	self.title_top:relayout()
	self.title_top:hard_set_cards()
	Scheduler.add{mode = "delayed", delay = change_context == "splash" and 4.05 or change_context == "game" and 3 or 0.4,
		blockable = false, blocking = false, func = function()
			MenuEffects.set_main_ui()
			return true
		end}
	Scheduler.add{blockable = false, func = function()
		runtime().REFRESH_ALERTS = true
		return true
	end}
	runtime().MAIN_MENU_VERSION_UI = UIViewHost.create{
		definition = {n = runtime().UI.ROOT, config = {align = "cm", colour = runtime().C.UI.TRANSPARENT_DARK}, nodes = {
			{n = runtime().UI.TEXT, config = {text = runtime().VERSION, scale = 0.3, colour = runtime().C.UI.TEXT_LIGHT}},
		}},
		config = {align = "tri", offset = {x = 0, y = 0}, major = runtime().ROOM_ATTACH, bond = "Weak"},
	}
end

return M
