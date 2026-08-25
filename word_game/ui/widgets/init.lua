--[[
	word_game/ui/widgets/ - Reusable UI controls: buttons, tabs, sliders, overlay chrome.

	These stay globals (`build_*`, `G.DEFINITIONS.*`) so existing call sites
	do not change. Loaded from app/bootstrap/game_boot.lua.
]]

local M = {}

G.DEFINITIONS = G.DEFINITIONS or {}

function G.DEFINITIONS.speech_bubble(text_key, loc_vars)
  local text = {}
  if loc_vars and loc_vars.quip then
    localize{type = 'quips', key = text_key or 'lq_1', vars = loc_vars or {}, nodes = text}
  else
    localize{type = 'tutorial', key = text_key or 'sb_1', vars = loc_vars or {}, nodes = text}
  end
  local row = {}
  for k, v in ipairs(text) do
    row[#row+1] = {n=G.UI.ROW, config={align = "cm"}, nodes=v}
  end
  local t = {n=G.UI.ROOT, config = {
    align = "cm",
    minw = 1.8,
    minh = 0.5,
    padding = 0.16,
    r = 0.22,
    colour = G.C.WHITE,
    shadow = true,
    outline = 1,
    outline_colour = G.C.BLACK,
    speech_tail = 'bl',
  }, nodes={
    {n=G.UI.COLUMN, config={align = "cm", colour = G.C.CLEAR}, nodes=row},
    {n=G.UI.BOX, config={h=0.1, w=0.01}},
  }}
  return t
end

require("word_game.ui.widgets.buttons")
require("word_game.ui.widgets.sliders")

function M.text(str, scale, colour)
	return { n = G.UI.TEXT, config = { text = str or "", scale = scale or 0.4, colour = colour or G.C.UI.TEXT_LIGHT, shadow = true } }
end

function M.row(nodes, extra)
	extra = extra or {}
	return { n = G.UI.ROW, config = extra.config or { align = extra.align or "cm", padding = extra.padding or 0.05 }, nodes = nodes }
end

function M.col(nodes, extra)
	extra = extra or {}
	return { n = G.UI.COLUMN, config = extra.config or { align = extra.align or "cm", padding = extra.padding or 0.05 }, nodes = nodes }
end

function M.button(label, func, colour, minw, minh)
	local button_colour = colour or G.C.UI.BUTTON
	return { n = G.UI.COLUMN, config = {
		align = "cm", minw = minw or 4.2, minh = minh or 0.7, r = 0.18, padding = 0.22,
		hover = true, colour = button_colour, hover_colour = G.C.UI.BUTTON_HOVER,
		button = func, shadow = true,
		emboss = 0.1,
 }, nodes = {{ n = G.UI.TEXT, config = { text = label, scale = 0.35, font = alpha_button_font(), colour = G.C.UI.BUTTON_TEXT, shadow = true } }} }
end

function M.item_card(title, body, price, func, sold, colour)
	local col = sold and G.C.UI.BACKGROUND_INACTIVE or (colour or G.C.UI.BUTTON)
	return { n = G.UI.COLUMN, config = { align = "cm", minw = 2.8, minh = 1.85, maxw = 3.0, r = 0.18, padding = 0.16, colour = G.C.BLACK, emboss = 0.1 }, nodes = {
  { n = G.UI.ROW, config = { align = "cm" }, nodes = {{ n = G.UI.TEXT, config = { text = title, scale = 0.32, font = alpha_button_font(), colour = G.C.GOLD, shadow = true } }} },
		{ n = G.UI.ROW, config = { align = "cm", minh = 0.65 }, nodes = {{ n = G.UI.TEXT, config = { text = body, scale = 0.24, colour = G.C.UI.TEXT_LIGHT, shadow = true } }} },
		 sold and { n = G.UI.ROW, config = { align = "cm" }, nodes = {{ n = G.UI.TEXT, config = { text = "SOLD", scale = 0.3, colour = G.C.RED, shadow = true } }} } or { n = G.UI.ROW, config = { align = "cm", minh = 0.62, padding = 0.16, r = 0.18, hover = true, colour = col, hover_colour = G.C.UI.BUTTON_HOVER, button = func, shadow = true, emboss = 0.1 }, nodes = {{ n = G.UI.TEXT, config = { text = type(price) == "number" and (price .. " Tokens") or tostring(price), scale = 0.28, colour = G.C.UI.BUTTON_TEXT, shadow = true } }} },
	}}
end

function M.open(definition, no_esc)
	G.SETTINGS.paused = true
	G.FUNCS.show_overlay({ definition = definition, config = { no_esc = no_esc } })
end

return M
