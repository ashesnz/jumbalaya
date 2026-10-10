--[[ word_game/ui/menu/definition.lua - Main menu UI definitions ]]

local game = require("word_game.ui.util.game_runtime").game
local shell = require("word_game.ui.facade").shell()

local Components = require("word_game.ui.widgets.components")
local Colour = require("jumbalaya-engine.util.colour")
local localize = require("word_game.ui.util.localize").localize
local each_utf8_char = require("word_game.ui.util.localize").each_utf8_char

local DEFINITIONS = game().DEFINITIONS

local M = {}

local STACK_GAP_PX = 20

local Panel = require("jumbalaya-engine.panels.api")
local Press = require("word_game.ui.widgets.press")

local function menu_px_to_tiles(px)
	local ts = (game().TILESIZE or 1) * (game().TILESCALE or 1)
	return px / ts
end

local function menu_button_chrome()
	return {
		align = "cm",
		padding = 0.24,
		r = Components.CHROME.radius,
		colour = game().C.L_BLACK,
		mid = true,
	}
end

local function menu_mode_chrome()
	local chrome = menu_button_chrome()
	chrome.no_stretch = true
	chrome.padding = 0
	return chrome
end

function DEFINITIONS.profile_select()
	shell.ensure_focused_profile(game().SETTINGS.profile or 1)

	local focused = shell.focused_profile()
	local t = build_generic_options({padding = 0, contents = {
			Panel.row({align = "cm", padding = 0, draw_layer = 1, minw = 4}, {
				make_tab_strip(
				{tabs = {
						{
								label = 1,
								chosen = focused == 1,
								tab_definition_function = DEFINITIONS.profile_option,
								tab_definition_function_args = 1
						},
						{
								label = 2,
								chosen = focused == 2,
								tab_definition_function = DEFINITIONS.profile_option,
								tab_definition_function_args = 2
						},
						{
								label = 3,
								chosen = focused == 3,
								tab_definition_function = DEFINITIONS.profile_option,
								tab_definition_function_args = 3
						}
				},
				snap_to_nav = true}),
			}),
	}})
	return t
end


function DEFINITIONS.profile_option(_profile)
	shell.set_focused_profile(_profile)
	local packed = read_game_save(shell.focused_profile() .. '/profile')
	local profile_data = packed and unpack_source(packed) or nil
	if profile_data then
		profile_data.name = profile_data.name or ("P".._profile)
	end
	game().PROFILES[_profile].name = profile_data and profile_data.name or ''

	local lwidth, rwidth, scale = 1, 1, 1
	game().CHECK_PROFILE_DATA = nil
	local t = Panel.root({align = 'cm', colour = game().C.CLEAR}, {
		Panel.row({align = 'cm',padding = 0.1, minh = 0.8}, {
				((_profile == game().SETTINGS.profile) or not profile_data) and Panel.row({align = "cm"}, {
				make_text_field({
					w = 4, max_length = 16, prompt_text = localize('term_enter_name'),
					ref_table = game().PROFILES[_profile], ref_value = 'name',extended_corpus = true, keyboard_offset = 1,
					callback = function() 
						game():queue_settings_write()
						game().WRITE_FLAGS.force = true
					end
				}),
			}) or Panel.row({align = 'cm',padding = 0.1, minw = 4, r = 0.1, colour = game().C.BLACK, minh = 0.6}, {
				Panel.label({text = game().PROFILES[_profile].name, scale = 0.45, colour = game().C.WHITE}),
			}),
		}),
		Panel.row({align = "cm", padding = 0.1}, {
			Panel.column({align = "cm", minw = 6}, {
				Panel.column({align = "cm", minh = 4, minw = 5.2, colour = game().C.BLACK, r = 0.1}, {
					Panel.label({text = localize('term_empty_caps'), scale = 0.5, colour = game().C.UI.TRANSPARENT_LIGHT})
				}),
			}),
			Panel.column({align = "cm", minh = 4}, {
				Panel.row({align = "cm", minh = 1}, {
					profile_data and Panel.row({align = "cm"}, {
						Panel.column({align = "cm", minw = lwidth}, {Panel.label({text = localize('term_wins'),colour = game().C.UI.TEXT_LIGHT, scale = scale*0.7})}),
						Panel.column({align = "cm"}, {Panel.label({text = ': ',colour = game().C.UI.TEXT_LIGHT, scale = scale*0.7})}),
						Panel.column({align = "cl", minw = rwidth}, {Panel.label({text = tostring(profile_data.career_stats.c_wins),colour = game().C.RED, shadow = true, scale = 1*scale})})
					}) or nil,
				}),
				Panel.row({align = "cm", padding = 0.2}, {
					Panel.row({align = "cm", padding = 0}, {
						Panel.row({align = "cm", minw = 4, maxw = 4, minh = 0.8, padding = 0.2, r = 0.1, hover = true, colour = game().C.BLUE,on_update = Press.named('can_load_profile'), on_press = Press.named("load_profile"), shadow = true, focus_args = {nav = 'wide'}}, {
							Panel.label({text = _profile == game().SETTINGS.profile and localize('ui_current_profile') or profile_data and localize('ui_load_profile') or localize('ui_create_profile'), ref_value = 'load_button_text', scale = 0.5, colour = game().C.UI.TEXT_LIGHT})
						})
					}),
					Panel.row({align = "cm", padding = 0, minh = 0.7}, {
						Panel.row({align = "cm", minw = 3, maxw = 4, minh = 0.6, padding = 0.2, r = 0.1, hover = true, colour = game().C.RED,on_update = Press.named('can_delete_profile'), on_press = Press.named("delete_profile"), shadow = true, focus_args = {nav = 'wide'}}, {
							Panel.label({text = _profile == game().SETTINGS.profile and localize('ui_reset_profile') or localize('ui_delete_profile'), scale = 0.3, colour = game().C.UI.TEXT_LIGHT})
						})
					}),
				}),
		}),
		}),
		Panel.row({align = "cm", padding = 0}, {
			Panel.label({id = 'warning_text', text = localize('hdr_click_confirm'), scale = 0.4, colour = game().C.CLEAR})
		})
	}) 
	return t
end


function M.build_profile_button()

	local letters = {}
	if game().F_DISP_USERNAME then
		for c in each_utf8_char(game().F_DISP_USERNAME) do
			local leng = game().LANGUAGES['all1'].font.FONT:hasGlyphs(c)
			letters[#letters+1] = Panel.label({lang = game().LANGUAGES[leng and 'all1' or 'all2'],text = c, scale = 0.3, colour = Colour.blend_colours(game().C.GREEN, game().C.WHITE, 0.7), shadow = true})
		end
	end

	if not game().PROFILES[game().SETTINGS.profile].name then 
		game().PROFILES[game().SETTINGS.profile].name = "P"..game().SETTINGS.profile
	end

	return Panel.root({align = "cm", colour = game().C.CLEAR}, {
		Panel.row({align = "cm", padding = 0.2, r = 0.1, emboss = 0.1, colour = game().C.L_BLACK}, {
			Panel.row({align = "cm"}, {
				Panel.label({text = localize('term_profile'), scale = 0.4, colour = game().C.UI.TEXT_LIGHT, shadow = true})
			}),
			Panel.row({align = "cm"}, {
				Panel.column({align = "cm", padding = 0.15, minw = 2, minh = 0.8, maxw = 2, r = 0.1, hover = true, colour = Colour.blend_colours(game().C.WHITE, game().C.GREY, 0.2), on_press = Press.named('profile_select'), shadow = true}, {
					Panel.label({ref_table = game().PROFILES[game().SETTINGS.profile], ref_value = 'name', scale = 0.4, colour = game().C.UI.TEXT_LIGHT, shadow = true})
				}),
			})
		}),
		game().F_DISP_USERNAME and Panel.row({align = "cm"}, {
			Panel.row({align = "cm"}, {
				Panel.label({text = localize('term_playing_as'), scale = 0.3, colour = game().C.UI.TEXT_LIGHT, shadow = true})
			}),
			Panel.row({align = "cm", minh = 0.12}, {}),
			Panel.row({align = "cm", maxw = 2}, letters)
		}) or nil,
	})
end

function M.build_main_menu_mode_buttons()
	return M.build_main_menu_buttons()
end

function M.build_main_menu_buttons()
	local text_size = 0.58
	local button_w, button_h = 3.4, 1.15
	local gap = 0.22
	local stack_gap = menu_px_to_tiles(STACK_GAP_PX)
	local chrome = menu_button_chrome()

	local function menu_button(id, label, action, colour)
		return Components.button{
			id = id,
			onClick = action,
			colour = colour,
			width = button_w,
			height = button_h,
			label = {label},
			textSize = text_size,
			col = true,
		}
	end

	local function mode_button(id, label, action, colour)
		return Panel.row({ align = "cm" }, {
			menu_button(id, label, action, colour),
		})
	end

	local function gap_node()
		return Panel.column({minw = gap}, {})
	end

	local function mode_stack()
		return Panel.row(menu_mode_chrome(), {
			mode_button('main_menu_classic', localize('ui_classic'), 'begin_classic_run', game().C.BLUE),
			Panel.row({minh = gap, minw = button_w}, {}),
			mode_button('main_menu_time_run', localize('ui_time_run'), 'begin_time_run', game().C.GREEN),
		})
	end

	return Panel.root({align = "cm", colour = game().C.CLEAR}, {
			Panel.column({align = "cm", padding = 0}, {
				Panel.row({
					id = "main_menu_mode_align_row",
					align = "cm",
					padding = 0,
					colour = game().C.CLEAR,
				}, {
					mode_stack(),
				}),
				Panel.row({minh = stack_gap}, {}),
				Panel.row(chrome, {
					menu_button(nil, localize('ui_settings'), 'open_settings', game().C.ORANGE),
					gap_node(),
					menu_button(nil, localize('ui_quit_cap'), 'quit', game().C.RED),
				}),
			}),
		})
end


function DEFINITIONS.language_selector()
	local rows = {}
	local langs = {}
	for k, v in pairs(game().LANGUAGES) do
		if not v.omit then 
			langs[#langs+1] = v
		end
	end
	table.sort(langs, (function(a, b) return a.label < b.label end))
	local _row = {}
	for k, v in ipairs(langs) do
		_row[#_row+1] = Panel.column({align = "cm", padding = 0.05, r = 0.1, minh = 0.7, minw = 4.5, on_press = Press.named('change_lang'), ref_table = v, colour = game().C.BLUE, hover = true, shadow = true, focus_args = {snap_to = (k == 1)}}, {
			Panel.row({align = "cm"}, {
				Panel.label({text = v.label, lang = v, scale = 0.45, colour = game().C.UI.TEXT_LIGHT, shadow = true})
			})
		})
		if _row[3] or (k == #langs) then 
			rows[#rows+1] = Panel.row({align = "cm", padding = 0.1}, _row)
			_row = {}
		end
	end
	
	local discord = Sprite(0,0,0.6,0.6,game().TEXTURE_ATLASES["icons"], {x=2, y=0})
	discord.states.drag.can = false

	local t = build_generic_options({contents ={
		Panel.row({align = "cm", padding = 0.05}, rows),
		Panel.row({align = "cm", padding = 0.05}, {
			Panel.column({align = "cm", padding = 0.1, minw = 4, maxw = 4, r = 0.1, minh = 0.8, colour = Colour.blend_colours(game().C.GREEN, game().C.GREY, 0.4)}, {
				Panel.object({object = discord}),
				Panel.label({text = game().LANG.button, scale = 0.45, colour = game().C.UI.TEXT_LIGHT, shadow = true})
			}),
		})
	}})
	return t
end

return M

