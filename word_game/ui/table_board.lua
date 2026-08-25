--[[
	word_game/ui/table_board.lua - TABLE_BOARD update and draw coordinator.
]]

local M = {}

local function boss_sequence_active()
	local felt = require("word_game.ui.layout.felt")
	return felt.is_boss_sequence()
end

local function hand_clear_focus_active()
	return G.HAND_CLEAR_OVERLAY ~= nil
end

function M.is_active()
	return G.STATE == G.STATES.TABLE_BOARD
end

function M.update(game, dt)
	if G.ARGS and G.ARGS.pending_layout then
		G.ARGS.pending_layout = false
		local Layout = require("word_game.ui.layout")
		Layout.refresh_placement_layout()
	end
	if DEVTOOLS and DEVTOOLS.DebugButton then
		DEVTOOLS.DebugButton.sync()
	end
		if WORD_GAME and WORD_GAME.HandShuffle then
			WORD_GAME.HandShuffle.sync_visibility()
		end
		if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_visibility then
			WORD_GAME.Sidebar.sync_visibility()
		end
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
		if WORD_GAME.Jumble.update_timer() then
			if WORD_GAME.Play and WORD_GAME.Play.end_jumble_hand then
				WORD_GAME.Play.end_jumble_hand()
			end
		else
			WORD_GAME.Jumble.refresh_hud()
		end
	end
	if game.placement_table then
		game.placement_table:update(dt)
	end
end

function M.draw_spotlight_overlay(game, overlay)
	if not overlay then return end
	love.graphics.push()
	overlay:translate_container()
	overlay:draw()
	love.graphics.pop()

	if overlay.redraw_portrait and WORD_GAME and WORD_GAME.PlayerPortrait then
		WORD_GAME.PlayerPortrait.draw()
	end
	if overlay.redraw_ally and WORD_GAME and WORD_GAME.PlayerPortrait and WORD_GAME.PlayerPortrait.draw_ally then
		WORD_GAME.PlayerPortrait.draw_ally()
	end
	if overlay.redraw_guest and WORD_GAME and WORD_GAME.PlayerPortrait and WORD_GAME.PlayerPortrait.draw_guest then
		WORD_GAME.PlayerPortrait.draw_guest()
	end
	if overlay.redraw_banner and WORD_GAME and WORD_GAME.ScoreBanner then
		WORD_GAME.ScoreBanner.draw()
	end
	if overlay.redraw_tokens and G.deck and not boss_sequence_active()
		and WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.draw then
		love.graphics.push()
		G.deck:translate_container()
		WORD_GAME.TableDeck.draw(G.deck)
		love.graphics.pop()
	end
	if overlay.redraw_confetti and WORD_GAME and WORD_GAME.Confetti then
		WORD_GAME.Confetti.draw_pass()
	end
	if overlay.redraw_token_reward and WORD_GAME and WORD_GAME.TokenReward then
		WORD_GAME.TokenReward.draw_pass()
	end
	if overlay.redraw_attention then
		for k, v in pairs(game.LIVE.UIBOX) do
			if v.spawn_attention and v ~= game.debug_tools and v ~= game.online_leaderboard and v ~= game.achievement_notification then
				love.graphics.push()
				v:translate_container()
				v:draw()
				love.graphics.pop()
			end
		end
		if WORD_GAME and WORD_GAME.FloatUpText then
			WORD_GAME.FloatUpText.draw_pass()
		end
	end

	if not overlay.selections then return end
	for _, v in ipairs(overlay.selections) do
		if v and not v.REMOVED then
			love.graphics.push()
			v:translate_container()
			v:draw()
			if v.draw_children then
				v:draw_self()
				v:draw_children()
			end
			love.graphics.pop()
		end
	end
end

function M.draw_hud()
	if WORD_GAME and WORD_GAME.PlayerPortrait then
		WORD_GAME.PlayerPortrait.draw()
		if WORD_GAME.PlayerPortrait.draw_ally then
			WORD_GAME.PlayerPortrait.draw_ally()
		end
		if WORD_GAME.PlayerPortrait.draw_guest then
			WORD_GAME.PlayerPortrait.draw_guest()
		end
	end
	if WORD_GAME and WORD_GAME.AllyHost then
		WORD_GAME.AllyHost.draw_pass()
	end
	if WORD_GAME and WORD_GAME.GuestHost then
		WORD_GAME.GuestHost.draw_pass()
	end
	if WORD_GAME and WORD_GAME.PlayerHost then
		WORD_GAME.PlayerHost.draw_pass()
	end
	if WORD_GAME and WORD_GAME.ScoreBanner then
		WORD_GAME.ScoreBanner.draw()
	end
end

function M.draw_board(game)
	if game.placement_table then
		game.placement_table:draw_run_pass(game)
		M.draw_hand_pass(game)
	end
end

function M.draw_hand_pass(game)
	if G.deck and #G.deck.cards > 0 and not boss_sequence_active() then
		love.graphics.push()
		G.deck:translate_container()
		G.deck:draw()
		love.graphics.pop()
	end

	if not G.hand or #G.hand.cards == 0 then return end

	love.graphics.push()
	G.hand:translate_container()
	G.hand:draw()
	love.graphics.pop()

	local controller = game.INPUT
	for _, v in pairs(game.LIVE.CARD) do
		if v.area == G.hand
			and (not v.parent and v ~= controller.dragging.target and v ~= controller.focused.target)
			and not (WORD_GAME and WORD_GAME.CardInspect and WORD_GAME.CardInspect.is(v)) then
			love.graphics.push()
			v:translate_container()
			v:draw()
			love.graphics.pop()
		end
	end
end

function M.draw_reward_passes()
	if hand_clear_focus_active() then return end
	if WORD_GAME and WORD_GAME.Confetti then
		WORD_GAME.Confetti.draw_pass()
	end
	if WORD_GAME and WORD_GAME.TokenReward then
		WORD_GAME.TokenReward.draw_pass()
	end
	if WORD_GAME and WORD_GAME.PerkMarketplace then
		WORD_GAME.PerkMarketplace.draw_pass()
	end
end

function M.draw_attention_passes(game)
	if hand_clear_focus_active() then return end
	for k, v in pairs(game.LIVE.UIBOX) do
		if v.spawn_attention and v ~= game.debug_tools and v ~= game.online_leaderboard and v ~= game.achievement_notification then
			love.graphics.push()
			v:translate_container()
			v:draw()
			love.graphics.pop()
		end
	end
	if WORD_GAME and WORD_GAME.FloatUpText then
		WORD_GAME.FloatUpText.draw_pass()
	end
end

function M.draw_card_interaction(game)
	if not game.placement_table then return end
	if game.INPUT.dragging.target and game.INPUT.dragging.target ~= game.INPUT.focused.target then
		love.graphics.push()
		game.INPUT.dragging.target:translate_container()
		game.INPUT.dragging.target:draw()
		love.graphics.pop()
	end

	if game.INPUT.focused.target and getmetatable(game.INPUT.focused.target) == Card
		and game.INPUT.focused.target.area == G.hand
		and game.INPUT.focused.target ~= game.INPUT.dragging.target then
		love.graphics.push()
		game.INPUT.focused.target:translate_container()
		game.INPUT.focused.target:draw()
		love.graphics.pop()
	end
	if WORD_GAME and WORD_GAME.CardInspect then
		WORD_GAME.CardInspect.draw_foreground()
	end
end

function M.draw_debug_answers()
	local text = "AVAILABLE ANSWERS\n"
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if jumble and jumble.is_active() and jumble.find_playable_words then
		local counts = jumble.jumble_hand_counts and jumble.jumble_hand_counts() or {}
		if G.hand and G.hand.cards and #G.hand.cards > 0
			and Dictionary and Dictionary.counts_from_cards then
			counts = Dictionary.counts_from_cards(G.hand.cards)
		end
		local words = jumble.find_playable_words(counts, jumble.state().puzzle, 12)
		text = text .. (#words > 0 and table.concat(words, ", ") or "none") .. "\n"
	else
		text = text .. "unavailable\n"
	end
	love.graphics.push()
	love.graphics.setColor(1, 1, 0, 1)
	love.graphics.print(text, 12, 40, 0, 0.65, 0.65)
	love.graphics.pop()
end

return M
