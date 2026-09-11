--[[
	word_game/ui/widgets/ - Reusable UIBox controls and chrome.

	`util/` holds stateless helpers (colour, roll math, localize). This package
	builds `runtime().DEFINITIONS.*` and shared control nodes loaded from game boot.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local Funcs = require("app.callbacks.funcs")
local function runtime() return GameRT.game() end

local M = {}

local DEFINITIONS = runtime().DEFINITIONS or {}
runtime().DEFINITIONS = DEFINITIONS

function DEFINITIONS.speech_bubble(text_key, loc_vars)
  local text = {}
  if loc_vars and loc_vars.quip then
    localize{type = 'quips', key = text_key or 'lq_1', vars = loc_vars or {}, nodes = text}
  else
    localize{type = 'tutorial', key = text_key, vars = loc_vars or {}, nodes = text}
  end
  local row = {}
  for k, v in ipairs(text) do
    row[#row+1] = {n=runtime().UI.ROW, config={align = "cm"}, nodes=v}
  end
  local t = {n=runtime().UI.ROOT, config = {
    align = "cm",
    minw = 1.8,
    minh = 0.5,
    padding = 0.16,
    r = 0.22,
    colour = runtime().C.WHITE,
    shadow = true,
    outline = 1,
    outline_colour = runtime().C.BLACK,
    speech_tail = 'bl',
  }, nodes={
    {n=runtime().UI.COLUMN, config={align = "cm", colour = runtime().C.CLEAR}, nodes=row},
    {n=runtime().UI.BOX, config={h=0.1, w=0.01}},
  }}
  return t
end

require("word_game.ui.widgets.buttons")
require("word_game.ui.widgets.sliders")

function M.text(str, scale, colour)
	return { n = runtime().UI.TEXT, config = { text = str or "", scale = scale or 0.4, colour = colour or runtime().C.UI.TEXT_LIGHT, shadow = true } }
end

function M.row(nodes, extra)
	extra = extra or {}
	return { n = runtime().UI.ROW, config = extra.config or { align = extra.align or "cm", padding = extra.padding or 0.05 }, nodes = nodes }
end

function M.col(nodes, extra)
	extra = extra or {}
	return { n = runtime().UI.COLUMN, config = extra.config or { align = extra.align or "cm", padding = extra.padding or 0.05 }, nodes = nodes }
end

function M.button(label, func, colour, minw, minh)
	local button_colour = colour or runtime().C.UI.BUTTON
	return { n = runtime().UI.COLUMN, config = {
		align = "cm", minw = minw or 4.2, minh = minh or 0.7, r = 0.18, padding = 0.22,
		hover = true, colour = button_colour, hover_colour = runtime().C.UI.BUTTON_HOVER,
		button = func, shadow = true,
		emboss = 0.1,
 }, nodes = {{ n = runtime().UI.TEXT, config = { text = label, scale = 0.35, font = alpha_button_font(), colour = runtime().C.UI.BUTTON_TEXT, shadow = true } }} }
end

function M.item_card(title, body, price, func, sold, colour)
	local col = sold and runtime().C.UI.BACKGROUND_INACTIVE or (colour or runtime().C.UI.BUTTON)
	return { n = runtime().UI.COLUMN, config = { align = "cm", minw = 2.8, minh = 1.85, maxw = 3.0, r = 0.18, padding = 0.16, colour = runtime().C.BLACK, emboss = 0.1 }, nodes = {
  { n = runtime().UI.ROW, config = { align = "cm" }, nodes = {{ n = runtime().UI.TEXT, config = { text = title, scale = 0.32, font = alpha_button_font(), colour = runtime().C.GOLD, shadow = true } }} },
		{ n = runtime().UI.ROW, config = { align = "cm", minh = 0.65 }, nodes = {{ n = runtime().UI.TEXT, config = { text = body, scale = 0.24, colour = runtime().C.UI.TEXT_LIGHT, shadow = true } }} },
		 sold and { n = runtime().UI.ROW, config = { align = "cm" }, nodes = {{ n = runtime().UI.TEXT, config = { text = "SOLD", scale = 0.3, colour = runtime().C.RED, shadow = true } }} } or { n = runtime().UI.ROW, config = { align = "cm", minh = 0.62, padding = 0.16, r = 0.18, hover = true, colour = col, hover_colour = runtime().C.UI.BUTTON_HOVER, button = func, shadow = true, emboss = 0.1 }, nodes = {{ n = runtime().UI.TEXT, config = { text = type(price) == "number" and (price .. " Tokens") or tostring(price), scale = 0.28, colour = runtime().C.UI.BUTTON_TEXT, shadow = true } }} },
	}}
end

function M.open(definition, no_esc)
	runtime().SETTINGS.paused = true
	Funcs.dispatch("show_overlay", { definition = definition, config = { no_esc = no_esc } })
end

return M
