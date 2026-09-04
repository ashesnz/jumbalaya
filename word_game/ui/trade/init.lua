--[[ word_game/ui/trade/init.lua - The Card Marketplace overlay ]]

local trade = require("word_game.model.trade")
local state = require("word_game.model.state")
local deck = require("word_game.model.cards.deck")
local trade_layout = require("word_game.ui.trade.layout")
local trade_fly = require("word_game.ui.trade.fly")
local trade_definition = require("word_game.ui.trade.definition")
local trade_draw = require("word_game.ui.trade.draw")
local trade_animate = require("word_game.ui.trade.animate")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

local offer
local session
local standalone = false
local ADD_COST_STEP = 10

local modal_offset_y = trade_layout.modal_offset_y
local modal_minh = trade_layout.modal_minh
local room_translate = trade_layout.room_translate

local open_overlay
local refresh_overlay
local rebuild_overlay
local finish_trade

local function reset_session(rolled)
	offer = rolled
	session = {
		add_done = false,
		remove_done = true,
		added = nil,
		removed = nil,
		add_cost_bonus = 0,
		modified = {},
		removing = {},
	}
	if rolled and rolled.showdown and not rolled.remove then
		session.remove_done = true
	end
end

function M.session_add_cost(session_state)
	return trade.ACTION_COSTS.add + (session_state and session_state.add_cost_bonus or 0)
end

function M.can_afford_action(action, session_state)
	local balance = state.tokens()
	if action == "add" then
		return balance >= M.session_add_cost(session_state)
	end
	if action == "remove" then
		return balance >= trade.ACTION_COSTS.remove
	end
	if action == "modifier" then
		return balance >= trade.ACTION_COSTS.modifier
	end
	return false
end

function M.is_action_disabled(action, item, session_state)
	if action == "add" then
		return not M.can_afford_action("add", session_state)
	end
	if action == "remove" then
		return not trade.item_in_deck(item) or not M.can_afford_action("remove", session_state)
	end
	if action == "modifier" then
		local already_modified = item.card and deck.is_modified(item.card)
		local modified_this_session = session_state
			and session_state.modified
			and session_state.modified[item]
		return not trade.item_in_deck(item)
			or modified_this_session
			or already_modified
			or not M.can_afford_action("modifier", session_state)
	end
	return true
end

local function def_ctx()
	return {
		host = M,
		get_offer = function() return offer end,
		get_session = function() return session end,
		modal_minh = modal_minh,
	}
end

local function draw_ctx()
	return {
		get_offer = function() return offer end,
		room_translate = room_translate,
	}
end

-- True when the token balance is lower than the cheapest action still
-- available on the board (Add is always offered; Remove/Modify only count
-- while an offered card is in the deck and eligible).
-- after_add_purchase: the add-cost bonus rises once the in-flight card lands,
-- so project the next add price when deciding whether to auto-close.
function M.cannot_afford_anything(opts)
	if not session or not offer then return false end
	local balance = state.tokens()
	local letters = (offer.add or offer).letters or {}
	local any_in_deck = false
	local modify_available = false
	for _, item in ipairs(letters) do
		if trade.item_in_deck(item) then
			any_in_deck = true
			if not session.modified[item]
				and not (item.card and deck.is_modified(item.card)) then
				modify_available = true
			end
		end
	end
	local min_cost = M.session_add_cost(session)
	if opts and opts.after_add_purchase then
		min_cost = min_cost + ADD_COST_STEP
	end
	if any_in_deck then
		min_cost = math.min(min_cost, trade.ACTION_COSTS.remove)
		if modify_available then
			min_cost = math.min(min_cost, trade.ACTION_COSTS.modifier)
		end
	end
	return balance < min_cost
end

local cannot_afford_anything = M.cannot_afford_anything

open_overlay = function()
	G.SETTINGS.paused = true
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.reset then
		WORD_GAME.PlayHoldRedraw.reset()
	end
	G.FUNCS.show_overlay({
		definition = M.definition(),
		config = { no_esc = true, offset = { x = 0, y = modal_offset_y() }, no_jiggle = true },
	})
end

-- Rebuilds the modal body without any affordability gating, so in-flight
-- animations can play out before the session is torn down.
rebuild_overlay = function()
	if not G.OVERLAY_MENU then
		open_overlay()
		return
	end
	local host = G.OVERLAY_MENU:find_node_by_id("trade_marketplace_body")
	if not host or not host.config then
		open_overlay()
		return
	end
	-- Remember the body's current height so the rebuilt body can never be
	-- shorter — the modal must not change size when a card is removed.
	local prev_body_h = nil
	if host.config.object and host.config.object.VT and host.config.object.VT.h then
		prev_body_h = host.config.object.VT.h
	end
	if host.config.object and host.config.object.remove then
		host.config.object:remove()
	end
	local body_def = trade_definition.marketplace_body_definition(def_ctx())
	if prev_body_h and body_def.config then
		body_def.config.minh = math.max(body_def.config.minh or 0, prev_body_h)
	end
	host.config.object = LayoutView{
		definition = body_def,
		config = { offset = { x = 0, y = 0 }, align = "cm", parent = host },
	}
	G.OVERLAY_MENU:recalculate()
end

refresh_overlay = function()
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	rebuild_overlay()
end

function M.definition()
	if not offer then
		reset_session(trade.roll_offer())
	elseif not session then
		reset_session(offer)
	end

	return trade_definition.build_overlay_definition(def_ctx())
end

local function close_menu()
	offer = nil
	session = nil
	trade_fly.clear()
	trade_animate.clear()
	if G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
end

local function continue_run()
	offer = nil
	session = nil
	if G.FUNCS.close_overlay then
		G.FUNCS.close_overlay()
	end
	if WORD_GAME and WORD_GAME.Play then
		WORD_GAME.Play.continue_after_dealer()
		return
	end
	close_menu()
end

finish_trade = function()
	trade.mark_used()
	if standalone then
		standalone = false
		close_menu()
		return
	end
	continue_run()
end

local function broke_after_last_action()
	return session and session.broke_after_action or false
end

trade_animate.init({
	refresh_overlay = refresh_overlay,
	finish_trade = finish_trade,
	broke_after_last_action = broke_after_last_action,
	get_offer = function() return offer end,
	get_session = function() return session end,
})

local function session_complete()
	return session and session.add_done and session.remove_done
end

local function refresh_or_finish()
	if session_complete() then
		finish_trade()
		return
	end
	refresh_overlay()
end

local function fail(text)
	word_feedback.show_screen_centered(tostring(text), G.C.RED, 1.4)
end

function M.is_flying()
	return trade_fly.is_flying()
end

function M.is_open()
	return offer ~= nil
end

--- Advance the marketplace card fly animation. Called from the post_input
--- updater so progress continues while G.SETTINGS.paused freezes game dt.
function M.step_card_fly(dt)
	return trade_fly.step_card_fly(dt)
end

function M.backdrop_pass()
	trade_draw.backdrop_pass(draw_ctx())
end

function M.is_transforming()
	return trade_animate.is_transforming()
end

function M.draw_pass()
	trade_fly.draw_pass()
end

function M.open()
	standalone = true
	reset_session(trade.roll_offer())
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	open_overlay()
end

function M.open_then_dealer()
	standalone = false
	local alpha = state.get()
	if (alpha and alpha.trade_used_this_hand) or not trade.can_use() then
		continue_run()
		return
	end
	reset_session(trade.roll_offer())
	if cannot_afford_anything() then
		finish_trade()
		return
	end
	open_overlay()
end

function M.on_pick(e)
	if trade_fly.is_flying() or trade_animate.is_transforming() then return end
	local ref = e and e.config and e.config.ref_table
	local item = ref and ref.item or ref
	local action = ref and ref.action or "add"
	if not item or not session then return end
	if action == "remove" and (session.removed or session.removing[item]) then return end
	if action == "modifier" and session.modified[item] then return end
	if not M.can_afford_action(action, session) then
		fail("Not enough tokens")
		return
	end

	local cost = action == "add" and M.session_add_cost(session) or nil
	local ok, result = trade.apply(item, { action = action, cost = cost, defer_used = true })
	if not ok then
		fail(result)
		return
	end
	-- Record whether this purchase drained us below every remaining action
	-- BEFORE the animation runs; the check at landing can be skewed by token
	-- rewards that land in the meantime. For adds, project the post-landing
	-- add-cost escalation so we do not keep the modal open when the next add
	-- would already be unaffordable.
	local broke_opts = action == "add" and { after_add_purchase = true } or nil
	session.broke_after_action = cannot_afford_anything(broke_opts)

	if action == "add" then
		if WORD_GAME and WORD_GAME.TokenReward and WORD_GAME.TokenReward.spend_fly then
			WORD_GAME.TokenReward.spend_fly(cost)
		elseif WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.spend_tokens_display then
			WORD_GAME.TableDeck.spend_tokens_display(cost)
		end
		local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
		local card = item.market_card
		local transform = card and card.T
		local start_x = transform and (transform.x + (transform.w or G.CARD_W) * 0.5) * ts
		local start_y = transform and (transform.y + (transform.h or G.CARD_H) * 0.5) * ts
		item.flying = true
		-- Rebuild without the affordability check: if this purchase broke
		-- us, the modal must stay open until the card finishes flying.
		rebuild_overlay()
		trade_fly.start_card_fly(item, function()
			if not session then return end
			item.flying = false
			session.add_cost_bonus = (session.add_cost_bonus or 0) + ADD_COST_STEP
			play_sfx("card_slide1", 1.05, 0.75)
			-- Now that the animation is done, close when nothing was
			-- affordable after the purchase (or still isn't).
			if broke_after_last_action() then
				finish_trade()
				return
			end
			refresh_overlay()
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
	refresh_overlay()
end

function M.on_skip_add()
	if trade_fly.is_flying() or trade_animate.is_transforming() then return end
	if not session or session.add_done then
		if session and session_complete() then finish_trade() end
		return
	end
	session.add_done = true
	session.added = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	refresh_or_finish()
end

function M.on_skip_remove()
	if trade_fly.is_flying() or trade_animate.is_transforming() then return end
	if not session or session.remove_done then
		if session and session_complete() then finish_trade() end
		return
	end
	session.remove_done = true
	session.removed = "skipped"
	play_sfx("cancel", 0.9, 0.45)
	refresh_or_finish()
end

function M.teardown_run()
	offer = nil
	session = nil
	standalone = false
	trade_fly.clear()
	trade_animate.clear()
end

return M
