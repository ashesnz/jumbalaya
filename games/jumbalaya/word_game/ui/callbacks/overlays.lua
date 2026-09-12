--[[ word_game/ui/callbacks/overlays.lua - Overlay screen FUNCS (stable names) ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local UIViewHost = require("jumbalaya-engine.panels.view_host")
local Funcs = require("app.callbacks.funcs")

local M = {}

function M.install()
	Funcs.register("open_options", function(e)
		runtime().SETTINGS.paused = true
		Funcs.dispatch("show_overlay", {
			definition = build_options(),
		})
	end)

	Funcs.register("open_settings", function(e, instant)
		runtime().SETTINGS.paused = true
		Funcs.dispatch("show_overlay", {
			definition = build_settings(),
			config = {offset = {x=0,y=instant and 0 or 10}}
		})
	end)

	Funcs.register("language_selection", function(e)
		runtime().SETTINGS.paused = true
		Funcs.dispatch("show_overlay", {
			definition = runtime().DEFINITIONS.language_selector(),
		})
	end)

	Funcs.register("profile_select", function(e)
		runtime().SETTINGS.paused = true
		runtime().focused_profile = runtime().SETTINGS.profile

		for i = 1, 3 do
			if i ~= runtime().focused_profile and love.filesystem.getInfo(i..'/'..'profile.acs') then runtime():load_profile(i) end
		end
		runtime():load_profile(runtime().focused_profile)

		Funcs.dispatch("show_overlay", {
			definition = runtime().DEFINITIONS.profile_select(),
		})
	end)

	Funcs.register("quit", function(e)
		love.event.quit()
	end)

	Funcs.register("warn_lang", function(e)
		local _infotip_object = runtime().OVERLAY_MENU:find_node_by_id('overlay_menu_infotip')
		if _infotip_object.config.set ~= e.config.ref_table.label then
			_infotip_object.config.object:remove()
			_infotip_object.config.object = UIViewHost.create{
				definition = overlay_infotip({e.config.ref_table.warning[1],e.config.ref_table.warning[2],e.config.ref_table.warning[3], lang = e.config.ref_table}),
				config = {offset = {x=0,y=0}, align = 'bm', parent = _infotip_object}
			}
			_infotip_object.config.object.root_node:pulse()
			_infotip_object.config.set = e.config.ref_table.label
			e.config.disable_button = true
			Scheduler.add{mode = 'delayed', delay = 0.06, blockable = false, blocking = false, func = function()
				play_sfx('generic1', 0.76, 0.4);return true end}

			Scheduler.add{mode = 'delayed', delay = 0.35, blockable = false, blocking = false, func = function()
				e.config.disable_button = nil;return true end}
			e.config.button = 'change_lang'
			play_sfx('generic1', 1, 0.4)
		end
	end)

	Funcs.register("change_lang", function(e)
		local lang = e.config.ref_table
		if not lang or lang == runtime().LANG then
			Funcs.dispatch("close_overlay")
		else
			runtime().SETTINGS.language = lang.key
			runtime():set_language()
			runtime():queue_wipe_transition({
				function()
					runtime():discard_run()
					runtime():load_card_definitions()
					runtime():open_main_menu()
					return true
				end,
			}, { flush_timeline = true })
		end
	end)

	Funcs.register("copy_run_seed", function(e)
		local game = game_access.get()
		local seed = game and game.seed_streams and game.seed_streams.seed
		if not seed then return end
		if runtime().F_LOCAL_CLIPBOARD then
			runtime().CLIPBOARD = seed
		else
			love.system.setClipboardText(seed)
		end
	end)

	Funcs.register("show_infotip", function(e)
		if e.config.ref_table then
			e.children.info = UIViewHost.create{
				definition = {n=runtime().UI.ROOT, config = {align = 'cm', colour = runtime().C.CLEAR, padding = 0.02}, nodes=e.config.ref_table},
				config = {offset = {x=-0.03,y=0}, align = 'cl', parent = e}
			}
			e.children.info:align_to_major()
			e.config.ref_table = nil
		end
	end)
end

return M
