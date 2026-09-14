--[[ word_game/ui/util/localize/catalog.lua - Parse localization tables once at language load ]]

local game = require("word_game.ui.util.game_runtime").game
local parse = require("word_game.ui.util.localize.parse")

local M = {}

function M.init_localization()
	game().localization.misc.v_dictionary_parsed = {}
	for k, v in pairs(game().localization.misc.v_dictionary or {}) do
		if type(v) == "table" then
			game().localization.misc.v_dictionary_parsed[k] = { multi_line = true }
			for kk, vv in ipairs(v) do
				game().localization.misc.v_dictionary_parsed[k][kk] = parse.parse_string(vv)
			end
		else
			game().localization.misc.v_dictionary_parsed[k] = parse.parse_string(v)
		end
	end

	game().localization.misc.v_text_parsed = {}
	for k, v in pairs(game().localization.misc.v_text or {}) do
		game().localization.misc.v_text_parsed[k] = {}
		for kk, vv in ipairs(v) do
			game().localization.misc.v_text_parsed[k][kk] = parse.parse_string(vv)
		end
	end

	game().localization.tutorial_parsed = {}
	for k, v in pairs(game().localization.misc.tutorial or {}) do
		game().localization.tutorial_parsed[k] = { multi_line = true }
		for kk, vv in ipairs(v) do
			game().localization.tutorial_parsed[k][kk] = parse.parse_string(vv)
		end
	end

	game().localization.quips_parsed = {}
	for k, v in pairs(game().localization.misc.quips or {}) do
		game().localization.quips_parsed[k] = { multi_line = true }
		for kk, vv in ipairs(v) do
			game().localization.quips_parsed[k][kk] = parse.parse_string(vv)
		end
	end

	for g_k, group in pairs(game().localization) do
		if g_k == "descriptions" then
			for _, set in pairs(group) do
				for _, center in pairs(set) do
					center.text_parsed = {}
					for _, line in ipairs(center.text) do
						center.text_parsed[#center.text_parsed + 1] = parse.parse_string(line)
					end
					center.name_parsed = {}
					for _, line in ipairs(type(center.name) == "table" and center.name or { center.name }) do
						center.name_parsed[#center.name_parsed + 1] = parse.parse_string(line)
					end
					if center.unlock then
						center.unlock_parsed = {}
						for _, line in ipairs(center.unlock) do
							center.unlock_parsed[#center.unlock_parsed + 1] = parse.parse_string(line)
						end
					end
				end
			end
		end
	end
end

return M
