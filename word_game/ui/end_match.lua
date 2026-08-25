--[[ word_game/ui/end_match.lua - End-of-Match results overlay ]]

local widgets = require("word_game.ui.widgets")
local state = require("word_game.model.state")
local vault = require("word_game.model.vault")
local almanac = require("word_game.model.almanac")
local Easing = require("app.effects.easing")

local M = {}

function M.definition(won)
	local alpha = state.get()
	local stats = alpha and alpha.stats or {}
	local counts = almanac.counts()
	local title = won and "MATCH WON" or "MATCH OVER"
	local colour = won and G.C.GOLD or G.C.RED

	return build_generic_options({
		contents = {
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.12 }, nodes = {
				{ n = G.UI.TEXT, config = { text = title, scale = 0.7, colour = colour, shadow = true } },
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
				{ n = G.UI.TEXT, config = { text = "Best word: " .. tostring(stats.best_word or "—") .. "  (" .. tostring(stats.best_word_score or 0) .. ")", scale = 0.36, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = G.UI.TEXT, config = { text = "Highest Boost: ×" .. tostring(stats.highest_boost or 0), scale = 0.36, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = G.UI.TEXT, config = { text = "Vault: " .. vault.count() .. " unique  ·  Sweeps: " .. tostring(stats.sweeps or 0), scale = 0.36, colour = G.C.GOLD, shadow = true } },
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.08 }, nodes = {
				{ n = G.UI.TEXT, config = {
					text = "Almanac  Perks " .. counts.perks.have .. "/" .. counts.perks.total
						.. "  Upgrades " .. counts.upgrades.have .. "/" .. counts.upgrades.total,
					scale = 0.3,
					colour = G.C.UI.TEXT_INACTIVE,
					shadow = true,
				}},
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.1 }, nodes = {
				widgets.button("Back to Menu", "return_to_menu", G.C.RED, 3.4, 0.75),
			}},
		},
		no_back = true,
	})
end

function M.stat_line(label, value)
	return { n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
		{ n = G.UI.TEXT, config = { text = label .. "  " .. tostring(value), scale = 0.38, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
	}}
end

function M.overlay_definition(won)
	local alpha = state.get()
	local stats = alpha and alpha.stats or {}
	local title = won and localize("hdr_you_win") or localize("hdr_game_over")
	if type(title) ~= "string" or title == "" then
		title = won and "YOU WIN!" or "GAME OVER"
	end
	local title_col = won and G.C.GOLD or G.C.RED
	local eased = deep_clone(title_col)
	eased[4] = 0
	Easing.value{ref_table = eased, ref_value = 4, mod = 0.8, floored = true}

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
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.12, colour = G.C.BLACK, r = 0.1, emboss = 0.05 }, nodes = {
				M.stat_line("Best word", tostring(stats.best_word or "—") .. "  (" .. tostring(stats.best_word_score or 0) .. ")"),
				M.stat_line("Words played", stats.words_played or 0),
				M.stat_line("Vault", vault.count() .. " unique"),
			}},
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
