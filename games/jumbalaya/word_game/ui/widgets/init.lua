--[[
	word_game/ui/widgets/ - Reusable panel controls and chrome.

	`util/` holds stateless helpers (colour, roll math, localize). This package
	builds `game().DEFINITIONS.*` and shared control nodes loaded from game boot.
]]

local localize = require("word_game.ui.util.localize").localize
local game = require("word_game.ui.util.game_runtime").game
local Funcs = require("app.callbacks.funcs")

local M = {}

local DEFINITIONS = game().DEFINITIONS or {}
local Panel = require("jumbalaya-engine.panels.api")
game().DEFINITIONS = DEFINITIONS

function DEFINITIONS.speech_bubble(text_key, loc_vars)
	local text = {}
	if loc_vars and loc_vars.quip then
		localize{type = 'quips', key = text_key or 'lq_1', vars = loc_vars or {}, nodes = text}
	else
		localize{type = 'tutorial', key = text_key, vars = loc_vars or {}, nodes = text}
	end
	local row = {}
	for k, v in ipairs(text) do
		row[#row+1] = Panel.row({align = "cm"}, v)
	end
	local t = Panel.root({
		align = "cm",
		minw = 1.8,
		minh = 0.5,
		padding = 0.16,
		r = 0.22,
		colour = game().C.WHITE,
		shadow = true,
		outline = 1,
		outline_colour = game().C.BLACK,
		speech_tail = 'bl',
	}, {
		Panel.column({align = "cm", colour = game().C.CLEAR}, row),
		Panel.box({h=0.1, w=0.01}),
	})
	return t
end

require("word_game.ui.widgets.buttons")
require("word_game.ui.widgets.sliders")

function M.text(str, scale, colour)
	return Panel.label({ text = str or "", scale = scale or 0.4, colour = colour or game().C.UI.TEXT_LIGHT, shadow = true })
end

function M.row(nodes, extra)
	extra = extra or {}
	return Panel.row(extra.config or { align = extra.align or "cm", padding = extra.padding or 0.05 }, nodes)
end

function M.col(nodes, extra)
	extra = extra or {}
	return Panel.column(extra.config or { align = extra.align or "cm", padding = extra.padding or 0.05 }, nodes)
end

function M.button(label, func, colour, minw, minh)
	local button_colour = colour or game().C.UI.BUTTON
	if type(func) == "string" then
		func = require("word_game.ui.widgets.press").named(func)
	end
	return Panel.column({
		align = "cm", minw = minw or 4.2, minh = minh or 0.7, r = 0.18, padding = 0.22,
		hover = true, colour = button_colour, hover_colour = game().C.UI.BUTTON_HOVER,
		on_press = func, shadow = true,
		emboss = 0.1,
	}, {Panel.label({ text = label, scale = 0.35, font = alpha_button_font(), colour = game().C.UI.BUTTON_TEXT, shadow = true })})
end

function M.item_card(title, body, price, func, sold, colour)
	local col = sold and game().C.UI.BACKGROUND_INACTIVE or (colour or game().C.UI.BUTTON)
	return Panel.column({ align = "cm", minw = 2.8, minh = 1.85, maxw = 3.0, r = 0.18, padding = 0.16, colour = game().C.BLACK, emboss = 0.1 }, {
	Panel.row({ align = "cm" }, {Panel.label({ text = title, scale = 0.32, font = alpha_button_font(), colour = game().C.GOLD, shadow = true })}),
		Panel.row({ align = "cm", minh = 0.65 }, {Panel.label({ text = body, scale = 0.24, colour = game().C.UI.TEXT_LIGHT, shadow = true })}),
		 sold and Panel.row({ align = "cm" }, {Panel.label({ text = "SOLD", scale = 0.3, colour = game().C.RED, shadow = true })}) or Panel.row({ align = "cm", minh = 0.62, padding = 0.16, r = 0.18, hover = true, colour = col, hover_colour = game().C.UI.BUTTON_HOVER, on_press = type(func) == "string" and require("word_game.ui.widgets.press").named(func) or func, shadow = true, emboss = 0.1 }, {Panel.label({ text = type(price) == "number" and (price .. " Tokens") or tostring(price), scale = 0.28, colour = game().C.UI.BUTTON_TEXT, shadow = true })}),
	})
end

function M.open(definition, no_esc)
	game().SETTINGS.paused = true
	Funcs.dispatch("show_overlay", { definition = definition, config = { no_esc = no_esc } })
end

return M

