--[[ word_game/ui/trade/nodes/chrome.lua - Shared marketplace chrome nodes ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

M.BUTTON_LABEL_SCALE = 0.38
M.MODIFIER_TEXT_SCALE = 0.30
M.MODIFIER_LINE_CHARS = 38
M.TOKEN_COIN_W = 0.24

function M.wrap_description(text, max_chars)
	max_chars = max_chars or M.MODIFIER_LINE_CHARS
	local words = {}
	for word in (text or ""):gmatch("%S+") do
		words[#words + 1] = word
	end
	local lines, current = {}, ""
	for _, word in ipairs(words) do
		local candidate = current == "" and word or (current .. " " .. word)
		if #candidate > max_chars and current ~= "" then
			lines[#lines + 1] = current
			current = word
		else
			current = candidate
		end
	end
	if current ~= "" then
		lines[#lines + 1] = current
	end
	return lines
end

function M.token_coin_node()
	local atlas = game() and game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.coin
	if not atlas or not atlas.image then
		return nil
	end
	local pw, ph = atlas.px, atlas.py
	if not pw or not ph then
		if not atlas.image.getDimensions then return nil end
		pw, ph = atlas.image:getDimensions()
	end
	local w = M.TOKEN_COIN_W
	local h = w * (ph / pw)
	local sprite = Sprite(0, 0, w, h, atlas, { x = 0, y = 0 })
	sprite.states.drag.can = false
	sprite.states.hover.can = false
	sprite.states.collide.can = false
	sprite.states.click.can = false
	return { n = game().UI.OBJECT, config = { object = sprite, w = w, h = h } }
end

function M.action_button_label_nodes(label, cost)
	local nodes = {
		{ n = game().UI.TEXT, config = {
			text = label,
			scale = M.BUTTON_LABEL_SCALE,
			font = alpha_button_font(),
			colour = game().C.UI.BUTTON_TEXT,
			shadow = true,
		}},
		{ n = game().UI.TEXT, config = {
			text = tostring(cost),
			scale = M.BUTTON_LABEL_SCALE,
			font = alpha_button_font(),
			colour = game().C.UI.BUTTON_TEXT,
			shadow = true,
		}},
	}
	local coin = M.token_coin_node()
	if coin then
		nodes[#nodes + 1] = coin
	end
	return nodes
end

function M.close_button_node(skip_func)
	return { n = game().UI.COLUMN, config = {
		align = "cm", minw = 2.2, minh = 0.5, r = 0.18, padding = 0.22,
		hover = true, colour = game().C.ORANGE, hover_colour = game().C.UI.BUTTON_HOVER,
		button = skip_func, shadow = true, emboss = 0.1, no_jiggle = true,
	}, nodes = {
		{ n = game().UI.TEXT, config = {
			text = "Close",
			scale = 0.35,
			font = alpha_button_font(),
			colour = game().C.UI.BUTTON_TEXT,
			shadow = true,
		}},
	}}
end

function M.status_or_skip(done, done_text, skip_func)
	if done then
		return { n = game().UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
			{ n = game().UI.TEXT, config = {
				text = done_text,
				scale = 0.28,
				colour = game().C.GOLD,
				shadow = true,
			}},
		}}
	end
	return { n = game().UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		M.close_button_node(skip_func)
	}}
end

function M.close_cross_node(market_card_scale)
	return { n = game().UI.ROW, config = { align = "cr", minw = 3.8 * game().CARD_W * market_card_scale }, nodes = {
		{ n = game().UI.COLUMN, config = {
			align = "cm", minw = 0.72, minh = 0.72, r = 0.16, padding = 0.1,
			hover = true, colour = game().C.RED, hover_colour = game().C.UI.BUTTON_HOVER,
			button = "trade_skip_add", shadow = true, emboss = 0.12, no_jiggle = true,
		}, nodes = {
			{ n = game().UI.TEXT, config = {
				text = "X",
				scale = 0.62,
				font = alpha_button_font(),
				colour = game().C.WHITE,
				shadow = true,
			}},
		}},
	}}
end

return M
