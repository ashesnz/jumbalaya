--[[ word_game/ui/end_match.lua - End-of-Match results overlay ]]

local widgets = require("word_game.ui.widgets")
local state = require("word_game.model.state")
local Easing = require("app.effects.easing")

local M = {}

function M.best_jumble_value(stats)
	stats = stats or {}
	local pattern = stats.best_puzzle
	local score = stats.best_puzzle_score or 0
	if type(pattern) ~= "string" or pattern == "" then
		return "—"
	end
	return tostring(pattern) .. "  (" .. tostring(score) .. ")"
end

function M.summary_lines(stats)
	stats = stats or {}
	return {
		{ label = "Your best jumble", value = M.best_jumble_value(stats) },
		{ label = "Words played", value = stats.words_played or 0 },
	}
end

local function match_stats()
	state.record_current_jumble_if_best()
	local alpha = state.get()
	return (alpha and alpha.stats) or {}
end

function M.definition(won)
	local stats = match_stats()
	local title = won and "MATCH WON" or "MATCH OVER"
	local colour = won and G.C.GOLD or G.C.RED
	local lines = M.summary_lines(stats)
	local contents = {
		{ n = G.UI.ROW, config = { align = "cm", padding = 0.12 }, nodes = {
			{ n = G.UI.TEXT, config = { text = title, scale = 0.7, colour = colour, shadow = true } },
		}},
	}
	for i, line in ipairs(lines) do
		local padding = i == 1 and 0.06 or 0.04
		contents[#contents + 1] = { n = G.UI.ROW, config = { align = "cm", padding = padding }, nodes = {
			{ n = G.UI.TEXT, config = {
				text = line.label .. ": " .. tostring(line.value),
				scale = 0.36,
				colour = G.C.UI.TEXT_LIGHT,
				shadow = true,
			}},
		}}
	end
	contents[#contents + 1] = { n = G.UI.ROW, config = { align = "cm", padding = 0.1 }, nodes = {
		widgets.button("Back to Menu", "return_to_menu", G.C.RED, 3.4, 0.75),
	}}

	return build_generic_options({
		contents = contents,
		no_back = true,
	})
end

function M.stat_line(label, value)
	return { n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
		{ n = G.UI.TEXT, config = { text = label .. "  " .. tostring(value), scale = 0.38, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
	}}
end

function M.overlay_definition(won)
	local stats = match_stats()
	local title = won and localize("hdr_you_win") or localize("hdr_game_over")
	if type(title) ~= "string" or title == "" then
		title = won and "YOU WIN!" or "GAME OVER"
	end
	local title_col = won and G.C.GOLD or G.C.RED
	local eased = deep_clone(title_col)
	eased[4] = 0
	Easing.value{ref_table = eased, ref_value = 4, mod = 0.8, floored = true}

	local stat_nodes = {}
	for _, line in ipairs(M.summary_lines(stats)) do
		stat_nodes[#stat_nodes + 1] = M.stat_line(line.label, line.value)
	end

	return build_generic_options({
		bg_colour = eased,
		no_back = true,
		padding = 0.08,
		contents = {
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.12 }, nodes = {
				{ n = G.UI.OBJECT, config = { object = FlowText({
					string = { title },
					colours = { title_col },
					shadow = true,
					float = true,
					scale = 1.35,
					pop_in = 0.4,
					maxw = 6.5,
				})}},
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.12, colour = G.C.BLACK, r = 0.1, emboss = 0.05 }, nodes = stat_nodes },
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.12 }, nodes = {
				{ n = G.UI.ROW, config = {
					id = "from_game_over",
					align = "cm",
					minw = 5,
					padding = 0.1,
					r = 0.1,
					hover = true,
					colour = G.C.RED,
					button = "notify_then_start_run",
					shadow = true,
					focus_args = { nav = "wide", snap_to = true },
				}, nodes = {
					{ n = G.UI.TEXT, config = { text = localize("ui_start_new_run"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT } },
				}},
				{ n = G.UI.ROW, config = { minh = 0.08 }, nodes = {} },
				{ n = G.UI.ROW, config = {
					align = "cm",
					minw = 5,
					padding = 0.1,
					r = 0.1,
					hover = true,
					colour = G.C.RED,
					button = "return_to_menu",
					shadow = true,
					focus_args = { nav = "wide" },
				}, nodes = {
					{ n = G.UI.TEXT, config = { text = localize("ui_main_menu"), scale = 0.5, colour = G.C.UI.TEXT_LIGHT } },
				}},
			}},
		},
	})
end

function M.open(won)
	widgets.open(won and M.definition(true) or M.overlay_definition(false), true)
end

return M
