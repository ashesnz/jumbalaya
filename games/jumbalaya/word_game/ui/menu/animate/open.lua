--[[ word_game/ui/menu/animate/open.lua - Main menu open sequence ]]

local facade = require("word_game.ui.facade")
local Back = facade.back()
local game_access = facade.game_access()
local game = require("word_game.ui.util.game_runtime").game
local Layout = require("word_game.ui.layout")
local Easing = require("word_game.ui.effects.easing")
local MenuEffects = require("word_game.ui.effects.menu")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local UIViewHost = require("jumbalaya-engine.panels.view_host")
local Funcs = require("app.callbacks.funcs")
local garden = require("word_game.ui.menu.animate.garden")

require("word_game.ui.menu.title_logo")

local M = {}

local TITLE_GARDEN_MOSS = {0.12, 0.24, 0.14, 1}


local function settle_main_menu_layout()
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
local retag_audio = require("jumbalaya-engine.sound.sound").retag_audio
	if layout_main_menu then
		layout_main_menu()
	end
	if game().title_top then
		game().title_top:sort("order")
		game().title_top:set_ranks()
		game().title_top:relayout()
		game().title_top:hard_set_cards()
	end
	if game().SPLASH_LOGO and game().SPLASH_LOGO.snap_VT then
		game().SPLASH_LOGO:snap_VT()
	end
end

function M.open_main_menu(self, change_context)
	if change_context ~= "splash" then
		game().TIMERS.REAL = 12
		game().TIMERS.TOTAL = 12
	else
		retag_audio(game().STATES.MENU)
	end

	self:prep_stage(game().STAGES.MAIN_MENU, game().STATES.MENU, true)
	game_access.patch({
		selected_back = Back.new(game().LETTERS.centers.deck_alpha),
	})

	if Funcs.get("change_shadows") and game().SETTINGS and game().SETTINGS.GRAPHICS then
		Funcs.dispatch("change_shadows", {to_key = game().SETTINGS.GRAPHICS.shadows == "On" and 1 or 2})
	end
	Easing.background_colour{new_colour = TITLE_GARDEN_MOSS, contrast = 1}
	if game().SPLASH_FRONT then game().SPLASH_FRONT:remove(); game().SPLASH_FRONT = nil end
	garden.setup_title_garden_background()

	Scheduler.add{mode = "instant", func = function()
		return true
	end}

	local scale = 1.1 * (game().debug_splash_size_toggle and 0.8 or 1)
	self.title_top = CardPile(0, 0, game().CARD_W, game().CARD_H, {card_limit = 1, type = "title"})
	local logo_atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.jumbalaya_base
	local logo_ratio = logo_atlas and logo_atlas.py and logo_atlas.px
		and logo_atlas.py / logo_atlas.px or (267 / 933)
	local logo_w, logo_h = 13 * scale, 13 * scale * logo_ratio
	if logo_atlas and game().TEXTURE_ATLASES.jumbalaya_start_a and game().TEXTURE_ATLASES.jumbalaya_end_a then
		game().SPLASH_LOGO = TitleLogo.create(self.title_top, logo_w, logo_h)
	else
		game().SPLASH_LOGO = Sprite(0, 0, logo_w, logo_h, logo_atlas, {x = 0, y = 0})
		game().SPLASH_LOGO:set_alignment({major = self.title_top, type = "cm", bond = "Strong", offset = {x = 0, y = 0}})
		game().SPLASH_LOGO:define_draw_steps({{shader = "dissolve"}})
	end
	game().SPLASH_LOGO.dissolve_colours = {game().C.WHITE, game().C.WHITE}
	game().SPLASH_LOGO.dissolve = 1

	local cold_boot = change_context == nil
	if cold_boot then
		MenuEffects.set_main_ui()
		settle_main_menu_layout()
	end

	Scheduler.add{mode = "delayed",
		delay = change_context == "splash" and 1.8 or change_context == "game" and 2 or 0.15,
		blockable = false, blocking = false, func = function()
		local crumple_variant = change_context == "splash" and 2 or 3
		if play_sfx then
			play_sfx("magic_crumple" .. crumple_variant, change_context == "splash" and 0.95 or 1.25, 0.85)
			play_sfx("whoosh1", 0.55, 0.7)
		end
			if game().SPLASH_LOGO then Easing.value{ref_table = game().SPLASH_LOGO, ref_value = "dissolve", mod = -1, delay = change_context == "splash" and 2.3 or 0.9} end
			if game().VIBRATION then game().VIBRATION = game().VIBRATION + 1.5 end
			return true
		end}
	Scheduler.delayed{delay = 0.1 + (change_context == "splash" and 2 or change_context == "game" and 1.5 or 0)}
	Scheduler.add{func = function() if game().INPUT then game().INPUT.lock_input = false end; return true end}
	Layout.set_screen_positions()
	if not cold_boot then
		self.title_top:sort("order")
		self.title_top:set_ranks()
		self.title_top:relayout()
		self.title_top:hard_set_cards()
	end
	if not cold_boot then
		Scheduler.add{mode = "delayed", delay = change_context == "splash" and 4.05 or change_context == "game" and 3 or 0.4,
			blockable = false, blocking = false, func = function()
				MenuEffects.set_main_ui()
				return true
			end}
	end
	Scheduler.add{blockable = false, func = function()
		game().REFRESH_ALERTS = true
		return true
	end}
	game().MAIN_MENU_VERSION_UI = UIViewHost.create{
		definition = {n = game().UI.ROOT, config = {align = "cm", colour = game().C.UI.TRANSPARENT_DARK}, nodes = {
			{n = game().UI.TEXT, config = {text = game().VERSION, scale = 0.3, colour = game().C.UI.TEXT_LIGHT}},
		}},
		config = {align = "tri", offset = {x = 0, y = 0}, major = game().ROOM_ATTACH, bond = "Weak"},
	}
end

return M
