--[[ word_game/ui/trade/handlers.lua - Marketplace pick and skip actions ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local trade_fly = require("word_game.ui.trade.fly")
local trade_animate = require("word_game.ui.trade.animate")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local session_state = require("word_game.ui.trade.session_state")
local affordability = require("word_game.ui.trade.affordability")
local lifecycle = require("word_game.ui.trade.lifecycle")

local M = {}


local function trade_model()
	return facade.trade()
end

local function fail(text)
	word_feedback.show_screen_centered(tostring(text), game().C.RED, 1.4)
end

function M.on_pick(e)
	if trade_fly.is_flying() or trade_animate.is_transforming() then return end
	local ref = e and e.config and e.config.ref_table
	local item = ref and ref.item or ref
	local action = ref and ref.action or "add"
	local session = session_state.session()
	if not item or not session then return end
	if action == "remove" and (session.removed or session.removing[item]) then return end
	if action == "modifier" and session.modified[item] then return end
	if not affordability.can_afford_action(action, session) then
		fail("Not enough tokens")
		return
	end

	local cost = action == "add" and affordability.session_add_cost(session) or nil
	local ok, result = trade_model().apply(item, { action = action, cost = cost, defer_used = true })
	if not ok then
		fail(result)
		return
	end
	local broke_opts = action == "add" and { after_add_purchase = true } or nil
	session.broke_after_action = affordability.cannot_afford_anything(
		session_state.offer(),
		session,
		broke_opts
	)

	if action == "add" then
		if WORD_GAME_UI.TokenReward and WORD_GAME_UI.TokenReward.spend_fly then
			WORD_GAME_UI.TokenReward.spend_fly(cost)
		elseif WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.spend_tokens_display then
			WORD_GAME_UI.TableDeck.spend_tokens_display(cost)
		end
		local card = item.market_card
		local transform = card and card.T
		local ts = (game().TILESCALE or 1) * (game().TILESIZE or 1)
		local start_x = transform and (transform.x + (transform.w or game().CARD_W) * 0.5) * ts
		local start_y = transform and (transform.y + (transform.h or game().CARD_H) * 0.5) * ts
		item.flying = true
		lifecycle.rebuild_overlay()
		trade_fly.start_card_fly(item, function()
			local active = session_state.session()
			if not active then return end
			item.flying = false
			active.add_cost_bonus = (active.add_cost_bonus or 0) + affordability.ADD_COST_STEP
			play_sfx("card_slide1", 1.05, 0.75)
			if session_state.broke_after_last_action() then
				lifecycle.finish_trade()
				return
			end
			lifecycle.refresh_overlay()
		end, start_x, start_y)
		return
	end

	play_sfx("card_slide1", 0.9, 0.8)
	if action == "remove" then
		trade_animate.start_remove_dissolve(item)
		return
	elseif action == "modifier" then
		session.modified[item] = true
		trade_animate.start_transform_fx(item)
		return
	end
	lifecycle.refresh_overlay()
end

function M.on_skip_add()
	if trade_fly.is_flying() or trade_animate.is_transforming() then return end
	local session = session_state.session()
	if not session or session.add_done then
		if session_state.session_complete() then lifecycle.finish_trade() end
		return
	end
	session.add_done = true
	session.added = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	lifecycle.refresh_or_finish()
end

function M.on_skip_remove()
	if trade_fly.is_flying() or trade_animate.is_transforming() then return end
	local session = session_state.session()
	if not session or session.remove_done then
		if session_state.session_complete() then lifecycle.finish_trade() end
		return
	end
	session.remove_done = true
	session.removed = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	lifecycle.refresh_or_finish()
end

return M
