--[[ word_game/ui/util/localize/lookup.lua - Resolve parsed localization blobs into UI copy ]]

local game = require("word_game.ui.util.game_runtime").game
local GameFiles = require("app.platform.game_files")

local M = {}

local function ensure_localization()
	local shell = game()
	if not shell then
		return false
	end
	if shell.localization and shell.localization.misc then
		return true
	end
	GameFiles.ensure_mounted()
	if shell.set_language then
		shell:set_language()
	end
	return shell.localization and shell.localization.misc
end

function M.localize(args, misc_cat)
	if not game() or not game().localization or not game().localization.misc then
		ensure_localization()
	end
	if not game() or not game().localization or not game().localization.misc then
		if type(args) == "string" then
			return args
		end
		if type(args) == "table" and args.key then
			return tostring(args.key)
		end
		return "ERROR"
	end

	if args and not (type(args) == "table") then
		if misc_cat and game().localization.misc[misc_cat] then
			return game().localization.misc[misc_cat][args] or "ERROR"
		end
		return (game().localization.misc.dictionary and game().localization.misc.dictionary[args]) or "ERROR"
	end

	local loc_target = nil
	local ret_string = nil
	local desc_set = function(set_name)
		return game().localization.descriptions[set_name]
	end
	if args.type == "other" then
		loc_target = desc_set("Other") and desc_set("Other")[args.key]
	elseif args.type == "descriptions" or args.type == "unlocks" then
		loc_target = desc_set(args.set) and desc_set(args.set)[args.key]
	elseif args.type == "tutorial" then
		loc_target = game().localization.tutorial_parsed[args.key]
	elseif args.type == "quips" then
		loc_target = game().localization.quips_parsed[args.key]
	elseif args.type == "raw_descriptions" then
		loc_target = desc_set(args.set) and desc_set(args.set)[args.key]
		local multi_line = {}
		if loc_target then
			for _, lines in ipairs(args.type == "unlocks" and loc_target.unlock_parsed or args.type == "name" and loc_target.name_parsed or args.type == "text" and loc_target or loc_target.text_parsed) do
				local final_line = ""
				for _, part in ipairs(lines) do
					local assembled_string = ""
					for _, subpart in ipairs(part.strings) do
						assembled_string = assembled_string .. (type(subpart) == "string" and subpart or args.vars[tonumber(subpart[1])] or "ERROR")
					end
					final_line = final_line .. assembled_string
				end
				multi_line[#multi_line + 1] = final_line
			end
		end
		return multi_line
	elseif args.type == "text" then
		loc_target = game().localization.misc.v_text_parsed[args.key]
	elseif args.type == "variable" then
		loc_target = game().localization.misc.v_dictionary_parsed[args.key]
		if not loc_target then
			return "ERROR"
		end
		if loc_target.multi_line then
			local assembled_strings = {}
			for k, v in ipairs(loc_target) do
				local assembled_string = ""
				for _, subpart in ipairs(v[1].strings) do
					assembled_string = assembled_string .. (type(subpart) == "string" and subpart or args.vars[tonumber(subpart[1])])
				end
				assembled_strings[k] = assembled_string
			end
			return assembled_strings or { "ERROR" }
		else
			local assembled_string = ""
			for _, subpart in ipairs(loc_target[1].strings) do
				assembled_string = assembled_string .. (type(subpart) == "string" and subpart or args.vars[tonumber(subpart[1])])
			end
			ret_string = assembled_string or "ERROR"
		end
	elseif args.type == "name_text" then
		if pcall(function()
			ret_string = game().localization.descriptions[(args.set or args.node.config.center.set)][args.key or args.node.config.center.key].name
		end) then
		else
			ret_string = "ERROR"
		end
	elseif args.type == "name" then
		local set = desc_set(args.set or args.node.config.center.set)
		loc_target = set and set[args.key or args.node.config.center.key]
	end

	if ret_string then
		return ret_string
	end

	if loc_target then
		for _, lines in ipairs(args.type == "unlocks" and loc_target.unlock_parsed or args.type == "name" and loc_target.name_parsed or (args.type == "text" or args.type == "tutorial" or args.type == "quips") and loc_target or loc_target.text_parsed) do
			local final_line = {}
			for _, part in ipairs(lines) do
				local assembled_string = ""
				for _, subpart in ipairs(part.strings) do
					assembled_string = assembled_string .. (type(subpart) == "string" and subpart or args.vars[tonumber(subpart[1])] or "ERROR")
				end
				local desc_scale = game().LANG.font.DESCSCALE
				if args.type == "name" then
					final_line[#final_line + 1] = {
						n = game().UI.OBJECT,
						config = {
							object = FlowText({
								string = { assembled_string },
								colours = { (part.control.V and args.vars.colours[tonumber(part.control.V)]) or (part.control.C and loc_colour(part.control.C)) or game().C.UI.TEXT_LIGHT },
								bump = true,
								silent = true,
								pop_in = 0,
								pop_in_rate = 4,
								maxw = 5,
								shadow = true,
								y_offset = -0.6,
								spacing = math.max(0, 0.32 * (17 - #assembled_string)),
								scale = (0.55 - 0.004 * #assembled_string) * (part.control.s and tonumber(part.control.s) or 1) * desc_scale,
							}),
						},
					}
				elseif part.control.E then
					local _float, _silent, _pop_in, _bump, _spacing = nil, true, nil, nil, nil
					if part.control.E == "1" then
						_float = true
						_silent = true
						_pop_in = 0
					elseif part.control.E == "2" then
						_bump = true
						_spacing = 1
					end
					final_line[#final_line + 1] = {
						n = game().UI.OBJECT,
						config = {
							object = FlowText({
								string = { assembled_string },
								colours = { part.control.V and args.vars.colours[tonumber(part.control.V)] or loc_colour(part.control.C or nil) },
								float = _float,
								silent = _silent,
								pop_in = _pop_in,
								bump = _bump,
								spacing = _spacing,
								scale = 0.32 * (part.control.s and tonumber(part.control.s) or 1) * desc_scale,
							}),
						},
					}
				elseif part.control.X then
					final_line[#final_line + 1] = {
						n = game().UI.COLUMN,
						config = { align = "m", colour = loc_colour(part.control.X), r = 0.05, padding = 0.03, res = 0.15 },
						nodes = {
							{
								n = game().UI.TEXT,
								config = {
									text = assembled_string,
									colour = loc_colour(part.control.C or nil),
									scale = 0.32 * (part.control.s and tonumber(part.control.s) or 1) * desc_scale,
								},
							},
						},
					}
				else
					final_line[#final_line + 1] = {
						n = game().UI.TEXT,
						config = {
							detailed_tooltip = part.control.T and game().LETTERS.centers[part.control.T] or nil,
							text = assembled_string,
							shadow = args.shadow,
							colour = part.control.V and args.vars.colours[tonumber(part.control.V)] or loc_colour(part.control.C or nil, args.default_col),
							scale = 0.32 * (part.control.s and tonumber(part.control.s) or 1) * desc_scale,
						},
					}
				end
			end
			if args.type == "name" or args.type == "text" then
				return final_line
			end
			args.nodes[#args.nodes + 1] = final_line
		end
	end
end

return M
