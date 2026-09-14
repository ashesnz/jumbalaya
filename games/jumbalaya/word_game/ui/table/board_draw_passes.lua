--[[ word_game/ui/table/board_draw_passes.lua - TABLE_BOARD draw pass lists ]]

local runtime = require("word_game.ui.util.game_runtime").game
local felt = require("word_game.ui.layout.felt")

local M = {}

local function boss_sequence_active()
	return felt.is_boss_sequence()
end

local function hand_clear_focus_active()
	return runtime().HAND_CLEAR_OVERLAY ~= nil
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
		M.ensure_placement_pattern_overlay(runtime().pattern_row)
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

function M.bind_pattern_overlay(ensure_fn)
	M.ensure_placement_pattern_overlay = ensure_fn
end

function M.draw_hud(is_active, draw_debug_fn)
	if WORD_GAME_UI.TimelineTimer then
		WORD_GAME_UI.TimelineTimer.draw()
	end
	if WORD_GAME_UI.ScoreBanner then
		WORD_GAME_UI.ScoreBanner.draw()
	end
	if is_active and draw_debug_fn then
		draw_debug_fn()
	end
end

local function draw_action_bar(bar)
	if not bar or bar.REMOVED then return end
	love.graphics.push()
	bar:translate_container()
	bar:draw()
	love.graphics.pop()
end

function M.draw_table_controls(is_active)
	if not is_active then return end
	draw_action_bar(runtime().table_shuffle_bar)
	draw_action_bar(runtime().hand_action_bar)
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

function M.draw_attention_passes()
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

	local pattern_area = runtime().pattern_row and runtime().pattern_row.area
	if game.INPUT.focused.target and getmetatable(game.INPUT.focused.target) == Card
		and (game.INPUT.focused.target.area == runtime().dealt_letters
			or (pattern_area and game.INPUT.focused.target.area == pattern_area)
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

return M
