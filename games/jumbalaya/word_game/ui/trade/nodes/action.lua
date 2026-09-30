--[[ word_game/ui/trade/nodes/action.lua - Marketplace action button columns ]]

local game = require("word_game.ui.util.game_runtime").game

local chrome = require("word_game.ui.trade.nodes.chrome")
local face_nodes = require("word_game.ui.trade.nodes.face")
local modifier_nodes = require("word_game.ui.trade.nodes.modifier")

local M = {}

local function action_button(item, action, cost, colour, disabled, market_card_scale)
	local ref = { item = item, action = action }
	local label = action == "modifier" and "Modify" or (action:gsub("^%l", string.upper))
	return { n = game().UI.ROW, config = {
		align = "cm", padding = 0.12, r = 0.18, minw = game().CARD_W * market_card_scale + 0.45, minh = 0.62,
		hover = not disabled, button = disabled and nil or "trade_pick", ref_table = ref,
		colour = disabled and game().C.UI.BACKGROUND_INACTIVE or colour or game().C.UI.BUTTON,
		hover_colour = game().C.UI.BUTTON_HOVER, shadow = true, emboss = 0.1, no_jiggle = true,
	}, nodes = {
		{ n = game().UI.ROW, config = { align = "cm", padding = 0.05 }, nodes = chrome.action_button_label_nodes(label, cost) },
	}}
end

function M.action_column(item, session_state, host, market_card_scale, deck_model, trade_model, column_minh)
	local add_cost = host.session_add_cost(session_state)
	local add_disabled = host.is_action_disabled("add", item, session_state)
	local modify_disabled = host.is_action_disabled("modifier", item, session_state)
	local remove_disabled = host.is_action_disabled("remove", item, session_state)
	local column_nodes = {}
	local deck_count = modifier_nodes.deck_count_node(item, deck_model, market_card_scale)
	if deck_count then
		column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = { deck_count } }
	elseif item.letter then
		column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.02 }, nodes = {
			modifier_nodes.deck_count_node(item, deck_model, market_card_scale, true),
		}}
	end
	column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.03 }, nodes = {
		face_nodes.face_node(item, market_card_scale, deck_model, trade_model),
	}}
	local desc = nil
	if not item.removed and (item.mode ~= "remove" or trade_model().item_in_deck(item)) then
		desc = modifier_nodes.modifier_description_node(item, deck_model, market_card_scale)
	elseif item.letter then
		desc = modifier_nodes.modifier_description_node(item, deck_model, market_card_scale, true)
	end
	if desc then
		column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.0 }, nodes = { desc } }
	end
	column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "add", add_cost, game().C.BLUE, add_disabled, market_card_scale),
	}}
	column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "remove", 20, game().C.RED, remove_disabled, market_card_scale),
	}}
	column_nodes[#column_nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
		action_button(item, "modifier", 30, game().C.GOLD, modify_disabled, market_card_scale),
	}}
	return { n = game().UI.COLUMN, config = {
		align = "cm",
		padding = 0.2,
		minw = game().CARD_W * market_card_scale + 0.7,
		minh = column_minh,
	}, nodes = column_nodes }
end

local function card_row_slice(items, session_state, host, market_card_scale, deck_model, trade_model, layout)
	local cards = {}
	local column_minh = layout and layout.column_minh
	local grid_w = layout and layout.grid_w
	for _, item in ipairs(items or {}) do
		cards[#cards + 1] = M.action_column(
			item, session_state, host, market_card_scale, deck_model, trade_model, column_minh
		)
	end
	return { n = game().UI.ROW, config = {
		align = "cm",
		padding = 0.12,
		minh = column_minh,
		minw = grid_w,
	}, nodes = cards }
end

function M.card_row(items, session_state, host, market_card_scale, deck_model, trade_model, layout)
	layout = layout or {}
	local columns = math.max(1, layout.columns or 3)
	local row_nodes = {}
	local list = items or {}
	for start = 1, #list, columns do
		local slice = {}
		for i = start, math.min(start + columns - 1, #list) do
			slice[#slice + 1] = list[i]
		end
		row_nodes[#row_nodes + 1] = card_row_slice(slice, session_state, host, market_card_scale, deck_model, trade_model, layout)
	end
	if #row_nodes == 1 then
		return row_nodes[1]
	end
	return { n = game().UI.COLUMN, config = { align = "cm", padding = 0.1 }, nodes = row_nodes }
end

return M
