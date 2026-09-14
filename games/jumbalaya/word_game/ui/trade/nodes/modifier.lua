--[[ word_game/ui/trade/nodes/modifier.lua - Modifier description and deck count nodes ]]

local game = require("word_game.ui.util.game_runtime").game

local chrome = require("word_game.ui.trade.nodes.chrome")

local M = {}

function M.modifier_description_node(item, deck_model, market_card_scale, placeholder)
	local text = deck_model().modifier_description(item and item.letter)
	if not text then return nil end
	local lines = chrome.wrap_description(text)
	local line_nodes = {}
	for _, line in ipairs(lines) do
		line_nodes[#line_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = {
			{ n = game().UI.TEXT, config = {
				text = line,
				scale = chrome.MODIFIER_TEXT_SCALE,
				font = alpha_button_font(),
				colour = placeholder and game().C.CLEAR or (game().C.BLACK or { 0, 0, 0, 1 }),
				shadow = false,
			}},
		}}
	end
	return { n = game().UI.COLUMN, config = {
		align = "cm",
		padding = 0.08,
		minw = game().CARD_W * market_card_scale + 0.35,
		minh = math.max(0.5, #lines * 0.28) + 0.12,
		r = 0.14,
		colour = placeholder and game().C.CLEAR or { 0.97, 0.93, 0.84, 1 },
		shadow = not placeholder and true or nil,
	}, nodes = line_nodes }
end

function M.deck_count_node(item, deck_model, market_card_scale, placeholder)
	if not item or not item.letter then return nil end
	local count = deck_model().count_letters_in_deck(item.letter)
	local text = tostring(count) .. " in deck"
	return { n = game().UI.COLUMN, config = {
		align = "cm",
		padding = 0.08,
		minw = game().CARD_W * market_card_scale + 0.35,
		minh = math.max(0.5, 0.28) + 0.12,
		r = 0.14,
		colour = placeholder and game().C.CLEAR or { 0.97, 0.93, 0.84, 1 },
		shadow = not placeholder and true or nil,
	}, nodes = {
		{ n = game().UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = {
			{ n = game().UI.TEXT, config = {
				text = text,
				scale = chrome.MODIFIER_TEXT_SCALE,
				font = alpha_button_font(),
				colour = placeholder and game().C.CLEAR or (game().C.BLACK or { 0, 0, 0, 1 }),
				shadow = false,
			}},
		}},
	}}
end

return M
