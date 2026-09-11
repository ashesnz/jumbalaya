--[[ word_game/ui/callbacks/overlays.lua - Overlay screen runtime().FUNCS (stable names) ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local game_access = require("word_game.model.game_access")
local UIViewHost = require("word_game.ui.views.ui_view_host")

local M = {}

function M.install()
	runtime().FUNCS.open_options = function(e)
		runtime().SETTINGS.paused = true
		runtime().FUNCS.show_overlay{
			definition = build_options(),
		}
	end

	runtime().FUNCS.open_settings = function(e, instant)
		runtime().SETTINGS.paused = true
		runtime().FUNCS.show_overlay{
			definition = build_settings(),
			config = {offset = {x=0,y=instant and 0 or 10}}
		}
	end

	runtime().FUNCS.language_selection = function(e)
		runtime().SETTINGS.paused = true
		runtime().FUNCS.show_overlay{
			definition = runtime().DEFINITIONS.language_selector(),
		}
	end

	runtime().FUNCS.profile_select = function(e)
		runtime().SETTINGS.paused = true
		runtime().focused_profile = runtime().SETTINGS.profile

		for i = 1, 3 do
			if i ~= runtime().focused_profile and love.filesystem.getInfo(i..'/'..'profile.acs') then runtime():load_profile(i) end
		end
		runtime():load_profile(runtime().focused_profile)

		runtime().FUNCS.show_overlay{
			definition = runtime().DEFINITIONS.profile_select(),
		}
	end

	runtime().FUNCS.quit = function(e)
		love.event.quit()
	end

	runtime().FUNCS.warn_lang = function(e)
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
	end

	runtime().FUNCS.change_lang = function(e)
		local lang = e.config.ref_table
		if not lang or lang == runtime().LANG then
			runtime().FUNCS.close_overlay()
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
	end

	runtime().FUNCS.copy_run_seed = function(e)
		local game = game_access.get()
		local seed = game and game.seed_streams and game.seed_streams.seed
		if not seed then return end
		if runtime().F_LOCAL_CLIPBOARD then
			runtime().CLIPBOARD = seed
		else
			love.system.setClipboardText(seed)
		end
	end

	runtime().FUNCS.show_infotip = function(e)
		if e.config.ref_table then
			e.children.info = UIViewHost.create{
				definition = {n=runtime().UI.ROOT, config = {align = 'cm', colour = runtime().C.CLEAR, padding = 0.02}, nodes=e.config.ref_table},
				config = {offset = {x=-0.03,y=0}, align = 'cl', parent = e}
			}
			e.children.info:align_to_major()
			e.config.ref_table = nil
		end
	end
end

return M
