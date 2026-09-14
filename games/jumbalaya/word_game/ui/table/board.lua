--[[ word_game/ui/table/board.lua - TABLE_BOARD update and draw coordinator ]]

local facade = require("word_game.ui.facade")
local runtime = require("word_game.ui.util.game_runtime").game

local M = {}

local views_install = require("word_game.ui.views.install")
local bridge = require("app.runtime")
local update_passes = require("word_game.ui.table.board_update_passes")
local draw_passes = require("word_game.ui.table.board_draw_passes")

local placement_snap = require("word_game.board.placement.snap")
local modifier_feedback = require("word_game.ui.feedback.modifier_feedback")
placement_snap.bind_modifier_feedback(function(card)
	modifier_feedback.show_on_placed_card(card)
end)

local jumble_fixed_letters = require("word_game.ui.table.jumble_fixed_letters")
local felt = require("word_game.ui.layout.felt")

local function ensure_placement_pattern_overlay(pt)
	if not pt or pt.draw_pattern_overlay then return end
	pt.draw_pattern_overlay = function(session)
		if not (facade.jumble().is_active()) then return end
		jumble_fixed_letters.draw(session)
	end
end

draw_passes.bind_pattern_overlay(ensure_placement_pattern_overlay)

function M.is_active()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
end

function M.ensure_store_subscription()
	if not bridge.store() then return nil end
	local engine = bridge.engine()
	if engine then
		views_install.install_table_board(engine)
	end
	return views_install.table_board_view()
end

function M.table_board_view()
	return views_install.table_board_view()
end

function M.update(game, dt)
	update_passes.run(game, dt, ensure_placement_pattern_overlay)
end

function M.draw_spotlight_overlay(game, overlay)
	draw_passes.draw_spotlight_overlay(game, overlay)
end

function M.draw_hud()
	draw_passes.draw_hud(M.is_active(), M.draw_debug_answers)
end

function M.draw_table_controls()
	draw_passes.draw_table_controls(M.is_active())
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
	if felt.is_boss_sequence() then return false end
	if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
		return true
	end
	local store = bridge.store()
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
	draw_passes.draw_reward_passes()
end

function M.draw_attention_passes()
	draw_passes.draw_attention_passes()
end

function M.draw_card_interaction(game)
	draw_passes.draw_card_interaction(game)
end

function M.draw_debug_answers()
	local text = "AVAILABLE ANSWERS\n"
	local jumble = facade.jumble()
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
