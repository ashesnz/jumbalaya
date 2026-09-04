--[[ word_game/ui/menu/animate.lua - Title garden pan and main menu open lifecycle ]]

local Layout = require "word_game.ui.layout"
local Easing = require "app.effects.easing"
local MenuEffects = require "app.effects.menu"
local Scheduler = require "app.effects.timeline_scheduler"

require "word_game.ui.title_logo"

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
	room = room or (G.ROOM and G.ROOM.T) or { w = 20, h = 11 }
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
	local sprite = G.SPLASH_BACK
	local pan = sprite and sprite.title_garden_pan
	if type(pan) ~= "table" then return end
	local off = sprite.alignment and sprite.alignment.offset
	if not off then return end
	dt = dt or (G and G.real_dt) or 0
	pan.t = (pan.t or 0) + dt
	off.x, off.y = M.title_garden_pan_offset(pan.t)
end

local function setup_title_garden_background()
	if G.SPLASH_BACK then
		G.SPLASH_BACK:remove()
		G.SPLASH_BACK = nil
	end

	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.title_garden
	if not atlas then return end

	local w, h = M.title_garden_sprite_dims()
	G.SPLASH_BACK = Sprite(-30, -13, w, h, atlas, {x = 0, y = 0})
	G.SPLASH_BACK:set_alignment({
		major = G.ROOM_ATTACH,
		type = "cm",
		bond = "Strong",
		offset = {x = 0, y = 0},
	})
	G.SPLASH_BACK.title_garden_pan = { t = 0 }
	G.SPLASH_BACK:define_draw_steps({{
		shader = "garden_title",
		send = {{name = "time", ref_table = G.TIMERS, ref_value = "REAL"}},
	}})
end

function M.open_main_menu(self, change_context)
	if change_context ~= "splash" then
		G.TIMERS.REAL = 12
		G.TIMERS.TOTAL = 12
	else
		retag_audio(G.STATES.MENU)
	end

	self:prep_stage(G.STAGES.MAIN_MENU, G.STATES.MENU, true)
	self.GAME.selected_back = WORD_GAME.Back.new(G.P_CENTERS.deck_alpha)

	if not G.SETTINGS.tutorial_complete and G.SETTINGS.tutorial_progress
		and G.SETTINGS.tutorial_progress.completed_parts
		and G.SETTINGS.tutorial_progress.completed_parts.big_blind then
		G.SETTINGS.tutorial_complete = true
	end
	if G.FUNCS and G.FUNCS.change_shadows and G.SETTINGS and G.SETTINGS.GRAPHICS then
		G.FUNCS.change_shadows{to_key = G.SETTINGS.GRAPHICS.shadows == "On" and 1 or 2}
	end
	Easing.background_colour{new_colour = TITLE_GARDEN_MOSS, contrast = 1}
	if G.SPLASH_FRONT then G.SPLASH_FRONT:remove(); G.SPLASH_FRONT = nil end
	setup_title_garden_background()

	Scheduler.add{mode = "instant", func = function()
		return true
	end}

	local scale = 1.1 * (G.debug_splash_size_toggle and 0.8 or 1)
	self.title_top = CardArea(0, 0, G.CARD_W, G.CARD_H, {card_limit = 1, type = "title"})
	local logo_atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.jumbalaya_base
	local logo_ratio = logo_atlas and logo_atlas.py and logo_atlas.px
		and logo_atlas.py / logo_atlas.px or (267 / 933)
	local logo_w, logo_h = 13 * scale, 13 * scale * logo_ratio
	if logo_atlas and G.TEXTURE_ATLASES.jumbalaya_start_a and G.TEXTURE_ATLASES.jumbalaya_end_a then
		G.SPLASH_LOGO = TitleLogo.create(self.title_top, logo_w, logo_h)
	else
		G.SPLASH_LOGO = Sprite(0, 0, logo_w, logo_h, logo_atlas, {x = 0, y = 0})
		G.SPLASH_LOGO:set_alignment({major = self.title_top, type = "cm", bond = "Strong", offset = {x = 0, y = 0}})
		G.SPLASH_LOGO:define_draw_steps({{shader = "dissolve"}})
	end
	G.SPLASH_LOGO.dissolve_colours = {G.C.WHITE, G.C.WHITE}
	G.SPLASH_LOGO.dissolve = 1

	Scheduler.add{mode = "delayed",
		delay = change_context == "splash" and 1.8 or change_context == "game" and 2 or 0.15,
		blockable = false, blocking = false, func = function()
		local crumple_variant = change_context == "splash" and 2 or 3
		if play_sfx then
			play_sfx("magic_crumple" .. crumple_variant, change_context == "splash" and 0.95 or 1.25, 0.85)
			play_sfx("whoosh1", 0.55, 0.7)
		end
			if G.SPLASH_LOGO then Easing.value{ref_table = G.SPLASH_LOGO, ref_value = "dissolve", mod = -1, delay = change_context == "splash" and 2.3 or 0.9} end
			if G.VIBRATION then G.VIBRATION = G.VIBRATION + 1.5 end
			return true
		end}
	Scheduler.delayed{delay = 0.1 + (change_context == "splash" and 2 or change_context == "game" and 1.5 or 0)}
	Scheduler.add{func = function() if G.INPUT then G.INPUT.lock_input = false end; return true end}
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
		G.REFRESH_ALERTS = true
		return true
	end}
	LayoutView{definition = {n = G.UI.ROOT, config = {align = "cm", colour = G.C.UI.TRANSPARENT_DARK}, nodes = {
		{n = G.UI.TEXT, config = {text = G.VERSION, scale = 0.3, colour = G.C.UI.TEXT_LIGHT}},
	}}, config = {align = "tri", offset = {x = 0, y = 0}, major = G.ROOM_ATTACH, bond = "Weak"}}
end

return M
