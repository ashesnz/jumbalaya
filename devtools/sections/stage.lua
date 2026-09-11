--[[ devtools/sections/stage.lua - Jump to a match stage from the debug panel. ]]

local layout = require "devtools.layout"
local round_config = require "word_game.config.gameplay.round"
local opening_deal = require "word_game.model.jumble_play.opening_deal"
local Funcs = require("bridge.funcs_registry")

-- Stage 1-3 boss word with two revealed letters → seven gutter bonus cards on 1-4.
local DEBUG_BOSS_WORD = "VEGETABLE"
local DEBUG_BOSS_PATTERN = "V_______E"

local function debug_bonus_letters()
	local letters = {}
	for index = 1, #DEBUG_BOSS_WORD do
		if DEBUG_BOSS_PATTERN:sub(index, index) == "_" then
			letters[#letters + 1] = DEBUG_BOSS_WORD:sub(index, index)
		end
	end
	return letters
end

local function destroy_bonus_stack_cards()
	local bonus_stack = WORD_GAME and WORD_GAME_UI.BonusStackUI
	local deck = WORD_GAME and WORD_GAME.Deck
	if not bonus_stack or not deck or not deck.destroy_card then return end
	for _, card in ipairs(bonus_stack.cards() or {}) do
		deck.destroy_card(card)
	end
	bonus_stack.clear()
end

local function seed_bonus_gutter()
	if not (WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.create_letter_card) then return end
	if not (WORD_GAME and WORD_GAME_UI.BonusStackUI and WORD_GAME_UI.BonusStackUI.promote_to_bonus) then
		return
	end

	destroy_bonus_stack_cards()

	local cards = {}
	for _, letter in ipairs(debug_bonus_letters()) do
		cards[#cards + 1] = WORD_GAME.Deck.create_letter_card(letter, "red")
	end
	WORD_GAME_UI.BonusStackUI.promote_to_bonus(cards)
end

local function jump_to_hand(ctx, set, hand_index)
	if not ctx:is_run_stage() then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if not (WORD_GAME and WORD_GAME.Round) then return end

	set = math.max(1, math.min(round_config.SETS_TO_WIN or 8, set))
	hand_index = math.max(1, math.min(round_config.hands_in_set(set), hand_index or 1))
	if G.GAME then
		G.GAME.word_score_animating = false
		G.GAME.hand_redraw_animating = false
	end
	if Funcs.get("close_overlay") then
		Funcs.dispatch("close_overlay")
	end
	if WORD_GAME_UI.PlayHoldRedraw and WORD_GAME_UI.PlayHoldRedraw.reset then
		WORD_GAME_UI.PlayHoldRedraw.reset()
	end
	if WORD_GAME_UI.HandClearFocus and WORD_GAME_UI.HandClearFocus.reset then
		WORD_GAME_UI.HandClearFocus.reset()
	end
	if WORD_GAME_UI.TokenReward and WORD_GAME_UI.TokenReward.reset then
		WORD_GAME_UI.TokenReward.reset()
	end
	local wr = G.GAME and G.GAME.word_round
	if wr and wr.jumble and WORD_GAME.Deck and WORD_GAME.Deck.destroy_boss_cards then
		WORD_GAME.Deck.destroy_boss_cards()
	end
	if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
		WORD_GAME_UI.ScoreBanner.set_banner_mode("normal")
	end

	WORD_GAME.Round.start_hand(set, hand_index)
	if WORD_GAME.Deck and WORD_GAME.Deck.reset_table_deck then
		WORD_GAME.Deck.reset_table_deck()
	end
	opening_deal.deal()
	if WORD_GAME_UI.Layout then
		if WORD_GAME_UI.Layout.refresh_placement_layout then
			WORD_GAME_UI.Layout.refresh_placement_layout()
		end
		if WORD_GAME_UI.Layout.request_refresh then
			WORD_GAME_UI.Layout.request_refresh()
		end
	end
	if G.pattern_row and G.pattern_row.apply_screen_position then
		G.pattern_row:apply_screen_position()
	end
	if set == 1 and hand_index == round_config.BONUS_STACK_HAND_FIRST then
		seed_bonus_gutter()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
	if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.sync_position then
		WORD_GAME_UI.TableControls.sync_position()
	end
	if WORD_GAME_UI.Sidebar then
		WORD_GAME_UI.Sidebar:refresh()
	end
	if WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	end
	play_sfx("generic1", 0.9, 0.7)
end

local HANDS = {
	{ set = 1, hand = 1, label = "1-1" },
	{ set = 1, hand = 3, label = "1-3 (boss)" },
	{ set = 1, hand = 4, label = "1-4" },
	{ set = 1, hand = 7, label = "1-7 (boss)" },
	{ set = 1, hand = 9, label = "1-9 (boss)" },
	{ set = 2, hand = 1, label = "2-1" },
	{ set = 2, hand = 3, label = "2-3 (boss)" },
}

return {
	id = "stage",
	order = 25,
	jump_to_hand = jump_to_hand,
	seed_bonus_gutter = seed_bonus_gutter,

	register = function(panel)
		for _, row in ipairs(HANDS) do
			local set, hand = row.set, row.hand
			panel:action("goto_hand_" .. set .. "_" .. hand, function(ctx)
				jump_to_hand(ctx, set, hand)
			end)
		end
	end,

	build = function(_panel)
		local buttons = {}
		for _, row in ipairs(HANDS) do
			buttons[#buttons + 1] = {
				label = row.label,
				action = "goto_hand_" .. row.set .. "_" .. row.hand,
			}
		end
		return layout.section("Stage", layout.button_columns(buttons, 3))
	end,
}
