--[[ word_game/ui/trade/refresh.lua - Refresh table + marketplace UI after token balance changes ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local session_state = require("word_game.ui.trade.session_state")
local offer_mod = require("word_game.ui.trade.offer")
local columns = require("word_game.ui.trade.columns")

local M = {}

local function refresh_token_display()
	local ui = rawget(_G, "WORD_GAME_UI")
	if not ui or not ui.TableDeck then return end
	if ui.TableDeck.uses_table_draw and ui.TableDeck.uses_table_draw() then
		if ui.TableDeck.sync_token_display then
			ui.TableDeck.sync_token_display()
		end
	end
end

local function refresh_hand_and_deck()
	local deck = facade.deck()
	if deck and deck.sync_deck_count_display then
		deck.sync_deck_count_display()
	end
	local ui = rawget(_G, "WORD_GAME_UI")
	if ui and ui.TableInput and ui.TableInput.refresh_card_input then
		ui.TableInput.refresh_card_input()
	end
end

local function refresh_marketplace_affordance()
	if not session_state.is_open() then return end
	local menu = game() and game().OVERLAY_MENU
	if not menu or not menu.find_node_by_id then return end
	local trade = facade.trade()
	local offer = offer_mod.current()
	if offer then
		trade.sync_offer_cards(offer)
	end
	columns.sync_action_affordance(menu)
	if menu.recalculate then
		menu:recalculate()
	end
end

function M.after_tokens_changed()
	refresh_token_display()
	refresh_hand_and_deck()
	refresh_marketplace_affordance()
end

return M
