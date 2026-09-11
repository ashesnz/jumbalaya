--[[
	word_game/ui/table/board.lua - TABLE_BOARD update and draw coordinator.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local M = {}

local views_install = require("word_game.ui.views.install")
local BridgeRuntime = require("bridge.runtime")

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
	return runtime().HAND_CLEAR_OVERLAY ~= nil
end

function M.is_active()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
end

function M.ensure_store_subscription()
	if not BridgeRuntime.store() then return nil end
	local engine = BridgeRuntime.engine()
	if engine then
		views_install.install_table_board(engine)
	end
	return views_install.table_board_view()
end

function M.table_board_view()
	return views_install.table_board_view()
end

function M.update(game, dt)
	if runtime().ARGS and runtime().ARGS.pending_layout then
		runtime().ARGS.pending_layout = false
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
	if overlay.redraw_tokens and runtime().draw_pile and not boss_sequence_active()
		and WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.draw then
		love.graphics.push()
		runtime().draw_pile:translate_container()
		WORD_GAME_UI.TableDeck.draw(runtime().draw_pile)
		love.graphics.pop()
	end
	if overlay.redraw_confetti and WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.draw_pass()
	end
	if overlay.redraw_token_reward and WORD_GAME_UI.TokenReward then
		WORD_GAME_UI.TokenReward.draw_pass()
	end
	if overlay.redraw_attention then
		if WORD_GAME_UI.FloatUpText then
			WORD_GAME_UI.FloatUpText.draw_pass()
		end
		if WORD_GAME_UI.BossWordAnnounce and WORD_GAME_UI.BossWordAnnounce.draw_pass then
			WORD_GAME_UI.BossWordAnnounce.draw_pass()
		end
	end

	if overlay.redraw_hand and runtime().dealt_letters then
		local bonus_stack = WORD_GAME_UI.BonusStackUI
		for _, v in pairs(game.LIVE.CARD) do
			if v.area == runtime().dealt_letters
				and (not v.parent and v ~= game.INPUT.dragging.target and v ~= game.INPUT.focused.target)
				and not (bonus_stack and bonus_stack.contains(v)) then
				love.graphics.push()
				v:translate_container()
				v:draw()
				love.graphics.pop()
			end
		end
	end

	if overlay.redraw_placement and runtime().pattern_row and runtime().pattern_row.draw_run_pass then
		ensure_placement_pattern_overlay(runtime().pattern_row)
		runtime().pattern_row:draw_run_pass(game)
	end

	if overlay.redraw_play and runtime().hand_action_bar and not runtime().hand_action_bar.REMOVED then
		love.graphics.push()
		runtime().hand_action_bar:translate_container()
		runtime().hand_action_bar:draw()
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

local function draw_action_bar(bar)
	if not bar or bar.REMOVED then return end
	love.graphics.push()
	bar:translate_container()
	bar:draw()
	love.graphics.pop()
end

function M.draw_table_controls()
	if not M.is_active() then return end
	draw_action_bar(runtime().table_shuffle_bar)
	draw_action_bar(runtime().hand_action_bar)
end

function M.draw_board(game)
	if game.pattern_row then
		ensure_placement_pattern_overlay(game.pattern_row)
		local table_view = M.ensure_store_subscription()
		if table_view and table_view:should_render_pattern_from_store() then
			love.graphics.push()
			if game.pattern_row.area then
				game.pattern_row.area:translate_container()
			end
			table_view:draw_pattern()
			love.graphics.pop()
		elseif game.pattern_row.draw_run_pass then
			game.pattern_row:draw_run_pass(game)
		end
		M.draw_hand_pass(game)
		M.draw_table_controls()
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
	local store = BridgeRuntime.store()
	if store then
		local state = store:get()
		if state.piles and state.piles.draw then
			return #state.piles.draw >= 0
		end
	end
	if not runtime().draw_pile then return false end
	return #runtime().draw_pile.cards > 0
end

local function draw_live_cards(cards, controller, skip)
	skip = skip or {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED and Card and getmetatable(card) == Card
			and not card.parent
			and not skip[card]
			and card ~= controller.dragging.target
			and card ~= controller.focused.target then
			love.graphics.push()
			card:translate_container()
			card:draw()
			love.graphics.pop()
		end
	end
end

function M.draw_hand_pass(game)
	local table_view = M.ensure_store_subscription()
	if not table_view then return end

	local controller = game.INPUT
	local sidebar_draws_deck = WORD_GAME_UI.Sidebar
		and runtime().STAGE == runtime().STAGES.RUN
		and runtime().STATE == runtime().STATES.TABLE_BOARD

	if M.should_draw_sidebar_deck() and not sidebar_draws_deck then
		love.graphics.push()
		if runtime().draw_pile then
			runtime().draw_pile:translate_container()
		end
		if table_view:should_render_draw_from_store() then
			local draw_cards = table_view:pile_cards("draw")
			if draw_cards and #draw_cards > 0 and Card and getmetatable(draw_cards[1]) == Card then
				draw_live_cards(draw_cards, controller)
			else
				table_view:draw_draw_pile()
			end
		elseif WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
			WORD_GAME_UI.TableDeck.draw(runtime().draw_pile)
		end
		love.graphics.pop()
	end

	if table_view:should_render_hand_from_store() then
		love.graphics.push()
		if runtime().dealt_letters then
			runtime().dealt_letters:translate_container()
		end
		local hand_cards = table_view:pile_cards("hand")
		if hand_cards and #hand_cards > 0 and Card and getmetatable(hand_cards[1]) == Card then
			draw_live_cards(hand_cards, controller)
		else
			table_view:draw_hand()
		end
		love.graphics.pop()
	end

	local bonus_stack = WORD_GAME_UI.BonusStackUI
	for _, v in pairs(game.LIVE.CARD) do
		local from_hand = v.area == runtime().dealt_letters
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
		and (game.INPUT.focused.target.area == runtime().dealt_letters
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
