--[[
	word_game/ui/table/board.lua - TABLE_BOARD update and draw coordinator.
]]

local M = {}

local Engine = require("jumbalaya-engine")
local Renderer = Engine.Renderer
local PileView = Engine.Views.PileView

local placement_snap = require("word_game.board.placement.snap")
local modifier_feedback = require("word_game.ui.feedback.modifier_feedback")
placement_snap.bind_modifier_feedback(function(card)
	modifier_feedback.show_on_placed_card(card)
end)

local jumble_fixed_letters = require("word_game.ui.table.jumble_fixed_letters")
local felt = require("word_game.ui.layout.felt")
local Layout = require("word_game.ui.layout")
local play_effects = require("word_game.ui.play_effects")

local function ensure_placement_pattern_overlay(pt)
	if not pt or pt.draw_pattern_overlay then return end
	pt.draw_pattern_overlay = function(session)
		if not (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()) then return end
		jumble_fixed_letters.draw(session)
	end
end

local function boss_sequence_active()
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
		Layout.refresh_placement_layout()
	end
	if DEVTOOLS and DEVTOOLS.DebugButton then
		DEVTOOLS.DebugButton.sync()
	end
		if WORD_GAME_UI.TableControls then
			WORD_GAME_UI.TableControls.sync()
		end
		if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.sync_visibility then
			WORD_GAME_UI.Sidebar.sync_visibility()
		end
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active() then
			if WORD_GAME.Jumble.update_timer() then
				if WORD_GAME.Play and WORD_GAME.Play.end_jumble_hand then
					WORD_GAME.Play.end_jumble_hand()
					if play_effects.present_end_jumble_sidebar then
						play_effects.present_end_jumble_sidebar()
					end
				end
			else
				WORD_GAME.Jumble.refresh_hud()
			end
		end
	if WORD_GAME_UI.BossWordAnnounce and WORD_GAME_UI.BossWordAnnounce.update then
		WORD_GAME_UI.BossWordAnnounce.update(dt)
	end
	if game.pattern_row then
		ensure_placement_pattern_overlay(game.pattern_row)
		game.pattern_row:update(dt)
	end
	if WORD_GAME_UI.TimelineTimer and WORD_GAME_UI.TimelineTimer.update then
		WORD_GAME_UI.TimelineTimer.update(dt)
	end
end

function M.draw_spotlight_overlay(game, overlay)
	if not overlay then return end
	love.graphics.push()
	overlay:translate_container()
	overlay:draw()
	love.graphics.pop()

	if overlay.redraw_portrait and WORD_GAME_UI.TimelineTimer then
		WORD_GAME_UI.TimelineTimer.draw()
	end
	if overlay.redraw_banner and WORD_GAME_UI.ScoreBanner then
		WORD_GAME_UI.ScoreBanner.draw()
	end
	if overlay.redraw_tokens and G.draw_pile and not boss_sequence_active()
		and WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.draw then
		love.graphics.push()
		G.draw_pile:translate_container()
		WORD_GAME_UI.TableDeck.draw(G.draw_pile)
		love.graphics.pop()
	end
	if overlay.redraw_confetti and WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.draw_pass()
	end
	if overlay.redraw_token_reward and WORD_GAME_UI.TokenReward then
		WORD_GAME_UI.TokenReward.draw_pass()
	end
	if overlay.redraw_attention then
		for k, v in pairs(game.LIVE.UIBOX) do
			if v.spawn_attention and v ~= game.debug_tools and v ~= game.online_leaderboard then
				love.graphics.push()
				v:translate_container()
				v:draw()
				love.graphics.pop()
			end
		end
		if WORD_GAME_UI.FloatUpText then
			WORD_GAME_UI.FloatUpText.draw_pass()
		end
		if WORD_GAME_UI.BossWordAnnounce and WORD_GAME_UI.BossWordAnnounce.draw_pass then
			WORD_GAME_UI.BossWordAnnounce.draw_pass()
		end
	end

	if overlay.redraw_hand and G.dealt_letters then
		local bonus_stack = WORD_GAME_UI.BonusStackUI
		for _, v in pairs(game.LIVE.CARD) do
			if v.area == G.dealt_letters
				and (not v.parent and v ~= game.INPUT.dragging.target and v ~= game.INPUT.focused.target)
				and not (bonus_stack and bonus_stack.contains(v)) then
				love.graphics.push()
				v:translate_container()
				v:draw()
				love.graphics.pop()
			end
		end
	end

	if overlay.redraw_placement and G.pattern_row and G.pattern_row.draw_run_pass then
		ensure_placement_pattern_overlay(G.pattern_row)
		G.pattern_row:draw_run_pass(game)
	end

	if overlay.redraw_play and G.hand_action_bar and not G.hand_action_bar.REMOVED then
		love.graphics.push()
		G.hand_action_bar:translate_container()
		G.hand_action_bar:draw()
		love.graphics.pop()
	end

	if overlay.redraw_timeline and WORD_GAME_UI.TimelineTimer then
		WORD_GAME_UI.TimelineTimer.draw()
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
	if WORD_GAME_UI.TimelineTimer then
		WORD_GAME_UI.TimelineTimer.draw()
	end
	if WORD_GAME_UI.ScoreBanner then
		WORD_GAME_UI.ScoreBanner.draw()
	end
	if M.is_active() then
		M.draw_debug_answers()
	end
end

function M.draw_board(game)
	if game.pattern_row then
		ensure_placement_pattern_overlay(game.pattern_row)
		game.pattern_row:draw_run_pass(game)
		M.draw_hand_pass(game)
	end
	local bonus_stack_ui = WORD_GAME_UI.BonusStackUI
	if bonus_stack_ui and bonus_stack_ui.draw_pass then
		bonus_stack_ui.draw_pass()
	end
end

function M.should_draw_sidebar_deck()
	if boss_sequence_active() then return false end
	if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
		return true
	end
	if G._store then
		local state = G._store:get()
		if state.piles and state.piles.draw then
			return #state.piles.draw >= 0
		end
	end
	if not G.draw_pile then return false end
	return #G.draw_pile.cards > 0
end

function M.draw_hand_pass(game)
	if M.should_draw_sidebar_deck() then
		love.graphics.push()
		if G.draw_pile then
			G.draw_pile:translate_container()
		end
		if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
			WORD_GAME_UI.TableDeck.draw(G.draw_pile)
		elseif G.draw_pile then
			G.draw_pile:draw()
		end
		love.graphics.pop()
	end

	if G._store then
		local state = G._store:get()
		if state.piles and state.piles.hand and #state.piles.hand > 0 and (not G.dealt_letters or #G.dealt_letters.cards == 0) then
			local pile_view = PileView.new("hand", state.piles.hand, { x = 0, y = 0, w = 5, h = 1 })
			pile_view:draw(Renderer.love2d())
		end
	end

	if not G.dealt_letters or #G.dealt_letters.cards == 0 then
		-- still draw bonus stack card overlays below
	else
		love.graphics.push()
		G.dealt_letters:translate_container()
		G.dealt_letters:draw()
		love.graphics.pop()
	end

	local bonus_stack = WORD_GAME_UI.BonusStackUI
	local controller = game.INPUT
	for _, v in pairs(game.LIVE.CARD) do
		local from_hand = v.area == G.dealt_letters
		local from_bonus = bonus_stack and bonus_stack.contains(v) and not v.area
		if (from_hand or from_bonus)
			and (not v.parent and v ~= controller.dragging.target and v ~= controller.focused.target)
			and not (WORD_GAME_UI.CardInspect and WORD_GAME_UI.CardInspect.is(v)) then
			love.graphics.push()
			v:translate_container()
			v:draw()
			love.graphics.pop()
		end
	end
end

function M.draw_reward_passes()
	if hand_clear_focus_active() then return end
	if WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.draw_pass()
	end
	if WORD_GAME_UI.TokenReward then
		WORD_GAME_UI.TokenReward.draw_pass()
	end
	if WORD_GAME_UI.PerkStamp then
		WORD_GAME_UI.PerkStamp.draw_pass()
	end
end

function M.draw_attention_passes(game)
	if hand_clear_focus_active() then return end
	for k, v in pairs(game.LIVE.UIBOX) do
		if v.spawn_attention and v ~= game.debug_tools and v ~= game.online_leaderboard then
			love.graphics.push()
			v:translate_container()
			v:draw()
			love.graphics.pop()
		end
	end
	if WORD_GAME_UI.FloatUpText then
		WORD_GAME_UI.FloatUpText.draw_pass()
	end
	if WORD_GAME_UI.BossWordAnnounce and WORD_GAME_UI.BossWordAnnounce.draw_pass then
		WORD_GAME_UI.BossWordAnnounce.draw_pass()
	end
end

function M.draw_card_interaction(game)
	if WORD_GAME_UI.FirstPlayTutorial and WORD_GAME_UI.FirstPlayTutorial.is_active()
		and WORD_GAME_UI.FirstPlayTutorial.is_active() then
		return
	end
	if not game.pattern_row then return end
	local bonus_stack = WORD_GAME_UI.BonusStackUI
	if game.INPUT.dragging.target and game.INPUT.dragging.target ~= game.INPUT.focused.target then
		love.graphics.push()
		game.INPUT.dragging.target:translate_container()
		game.INPUT.dragging.target:draw()
		love.graphics.pop()
	end

	if game.INPUT.focused.target and getmetatable(game.INPUT.focused.target) == Card
		and (game.INPUT.focused.target.area == G.dealt_letters
			or (bonus_stack and bonus_stack.contains(game.INPUT.focused.target)))
		and game.INPUT.focused.target ~= game.INPUT.dragging.target then
		love.graphics.push()
		game.INPUT.focused.target:translate_container()
		game.INPUT.focused.target:draw()
		love.graphics.pop()
	end
	if WORD_GAME_UI.CardInspect then
		WORD_GAME_UI.CardInspect.draw_foreground()
	end
	local voucher_discard = WORD_GAME_UI.VoucherDiscard
	if voucher_discard and voucher_discard.draw_voucher_foreground then
		voucher_discard.draw_voucher_foreground()
	end
end

function M.draw_debug_answers()
	local text = "AVAILABLE ANSWERS\n"
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if jumble and jumble.is_active() and jumble.find_playable_words then
		local counts = jumble.debug_answer_counts and jumble.debug_answer_counts()
			or (jumble.jumble_hand_counts and jumble.jumble_hand_counts() or {})
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
