--[[ word_game/ui/trade/refresh.lua - Refresh table + marketplace UI after token balance changes ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local session_state = require("word_game.ui.trade.session_state")
local offer_mod = require("word_game.ui.trade.offer")
local columns = require("word_game.ui.trade.columns")
local lifecycle = require("word_game.ui.trade.lifecycle")
local card_fly = require("word_game.ui.trade.card_fly")

local M = {}

local function refresh_sidebar_counters(spent_tokens)
	local deck = facade.deck()
	if deck and deck.sync_deck_count_display then
		deck.sync_deck_count_display()
	end
	local ui = rawget(_G, "WORD_GAME_UI")
	if ui and ui.TableDeck then
		if spent_tokens and spent_tokens > 0 and ui.TableDeck.spend_tokens_display then
			ui.TableDeck.spend_tokens_display(spent_tokens)
		elseif ui.TableDeck.sync_token_display then
			ui.TableDeck.sync_token_display()
		end
	end
	local g = game()
	local hud = g and g.SIDEBAR_HUD
	if hud and not hud.REMOVED and hud.recalculate then
		hud:recalculate()
	end
end

local function refresh_hand_and_deck()
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
	if card_fly.is_active() then
		return
	end
	if menu.recalculate then
		menu:recalculate()
	end
end

function M.close_if_nothing_affordable()
	if not session_state.is_open() then return end
	if card_fly.is_active() then return end
	if columns.any_action_affordable() then return end
	lifecycle.close()
end

function M.after_tokens_changed(opts)
	opts = opts or {}
	refresh_sidebar_counters(opts.spent)
	refresh_hand_and_deck()
	refresh_marketplace_affordance()
	M.close_if_nothing_affordable()
end

return M
