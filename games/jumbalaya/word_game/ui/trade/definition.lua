--[[ word_game/ui/trade/definition.lua - Marketplace UIBox composition root ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local chrome = require("word_game.ui.trade.nodes.chrome")
local action_nodes = require("word_game.ui.trade.nodes.action")
local trade_layout = require("word_game.ui.trade.layout")

local function trade_model()
	return facade.trade()
end

local function deck_model()
	return facade.deck()
end

local M = {}

M.MARKET_CARD_SCALE = 0.82

function M.marketplace_content_nodes(ctx)
	local offer = ctx.get_offer()
	local session = ctx.get_session()
	trade_model().sync_offer_cards(offer)
	local add = offer.add or offer
	local letters = add.letters or {}
	local layout = trade_layout.market_layout_metrics(#letters, M.MARKET_CARD_SCALE)
	local scale = layout.scale
	ctx.market_layout = layout
	local nodes = {
		chrome.close_cross_node(layout.grid_w),
		{ n = game().UI.ROW, config = { minh = 0.08 }, nodes = {} },
		action_nodes.card_row(letters, session, ctx.host, scale, deck_model, trade_model, layout),
	}

	if offer.showdown then
		local remove = offer.remove
		nodes[#nodes + 1] = { n = game().UI.ROW, config = { minh = 0.12 }, nodes = {} }
		nodes[#nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.03 }, nodes = {
			{ n = game().UI.TEXT, config = {
				text = "Remove a card from your pack",
				scale = 0.3,
				colour = game().C.RED,
				shadow = true,
			}},
		}}
		if remove and remove.letters and #remove.letters > 0 then
			local remove_layout = trade_layout.market_layout_metrics(#remove.letters, scale)
			nodes[#nodes + 1] = action_nodes.card_row(
				remove.letters, session, ctx.host, remove_layout.scale, deck_model, trade_model, remove_layout
			)
			nodes[#nodes + 1] = chrome.status_or_skip(
				session.remove_done,
				session.removed == "skipped" and "Remove skipped" or "Card removed",
				"trade_skip_remove"
			)
		else
			nodes[#nodes + 1] = { n = game().UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = game().UI.TEXT, config = {
					text = "No cards available to remove",
					scale = 0.28,
					colour = game().C.UI.TEXT_LIGHT,
					shadow = true,
				}},
			}}
		end
	end

	return nodes
end

function M.marketplace_body_definition(ctx)
	local content = M.marketplace_content_nodes(ctx)
	local layout = ctx.market_layout
	local minh = layout and layout.body_minh or trade_layout.body_min_height(M.MARKET_CARD_SCALE, 1)
	local minw = layout and layout.grid_w or trade_layout.grid_width(3, M.MARKET_CARD_SCALE)
	return {
		n = game().UI.ROOT,
		config = { align = "cm", colour = game().C.CLEAR, minw = minw, minh = minh },
		nodes = content,
	}
end

function M.build_overlay_definition(ctx)
	local TradeView = require("word_game.ui.views.trade_view")
	local minw = trade_layout.modal_minw()
	local minh = ctx.modal_minh()
	return build_generic_options({
		root_minw = minw + 1.5,
		root_minh = minh + 1.5,
		minw = minw,
		minh = minh,
		padding = trade_layout.modal_padding(),
		bg_colour = game().C.CLEAR,
		outline_colour = game().C.CLEAR,
		colour = game().C.CLEAR,
		contents = {
			{ n = game().UI.OBJECT, config = {
				id = "trade_marketplace_body",
				object = TradeView.create_marketplace_body(ctx),
			}},
		},
		no_back = true,
	})
end

return M
