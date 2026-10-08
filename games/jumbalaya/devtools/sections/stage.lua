--[[ devtools/sections/stage.lua - Jump to set boss (showdown) hands from the debug panel. ]]

local layout = require "devtools.layout"
local round_config = require "jumbalaya_core.config.gameplay.round"
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
local opening_deal = require "word_game.model.jumble_play.opening_deal"
local Funcs = require("app.callbacks.funcs")

local BOSS_HAND_INDEX = 3

local BOSS_SETS = {
	{ set = 1, label = "1-3" },
	{ set = 2, label = "2-3" },
	{ set = 3, label = "3-3" },
}

local function shell()
	return require("devtools.runtime").game()
end

local function jump_to_boss(ctx, set)
	if not ctx:is_run_stage() then return end
	local game = shell()
	if not game or game.STATE ~= game.STATES.TABLE_BOARD then return end
	if not (WORD_GAME and WORD_GAME.Round) then return end

	set = math.max(1, math.min(round_config.SETS_TO_WIN or 8, set))
	local hand_index = math.min(round_config.hands_in_set(set), BOSS_HAND_INDEX)

	WORD_GAME.GameAccess.patch({
		word_score_animating = false,
		hand_redraw_animating = false,
	})
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
	local wr = WORD_GAME.GameAccess.word_round()
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
	if game.pattern_row and game.pattern_row.apply_screen_position then
		game.pattern_row:apply_screen_position()
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

return {
	id = "stage",
	order = 25,

	register = function(panel)
		for _, row in ipairs(BOSS_SETS) do
			local set = row.set
			panel:action("goto_boss_" .. set, function(ctx)
				jump_to_boss(ctx, set)
			end)
		end
	end,

	build = function(_panel)
		local buttons = {}
		for _, row in ipairs(BOSS_SETS) do
			buttons[#buttons + 1] = {
				label = row.label,
				action = "goto_boss_" .. row.set,
			}
		end
		return layout.section("Stage", layout.button_columns(buttons, 3))
	end,
}
