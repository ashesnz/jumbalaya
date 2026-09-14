--[[ word_game/ui/trade/definition.lua - Marketplace UIBox composition root ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local chrome = require("word_game.ui.trade.nodes.chrome")
local action_nodes = require("word_game.ui.trade.nodes.action")

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
	local scale = M.MARKET_CARD_SCALE
	local nodes = {
		chrome.close_cross_node(scale),
		{ n = game().UI.ROW, config = { minh = 40 / (game().TILESIZE or 64) }, nodes = {} },
		action_nodes.card_row(add.letters, session, ctx.host, scale, deck_model, trade_model),
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
			nodes[#nodes + 1] = action_nodes.card_row(remove.letters, session, ctx.host, scale, deck_model, trade_model)
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
	return {
		n = game().UI.ROOT,
		config = { align = "cm", colour = game().C.CLEAR },
		nodes = M.marketplace_content_nodes(ctx),
	}
end

function M.build_overlay_definition(ctx)
	local TradeView = require("word_game.ui.views.trade_view")
	return build_generic_options({
		minw = 12,
		minh = ctx.modal_minh(),
		padding = 0.35,
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
