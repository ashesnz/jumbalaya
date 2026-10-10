--[[ tests/unit/test_table_controls_play_button.lua - Play button wiring regressions ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local Funcs = require("app.callbacks.funcs")

T.describe("table controls play button", function()
	mock_env.setup()
	mock_env.ensure_card_class()

	local function base_wr()
		return {
			target = 100,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
	end

	local function install_table_board()
		mock_env.setup()
		local game = shell.game()
		if not _G.get_hand_area_width then
			function get_hand_area_width(hand_size)
				local spacing = game.HAND_CARD_SPACING or 0.78
				return game.CARD_W + math.max(hand_size - 1, 0) * game.CARD_W * spacing
			end
		end
		game.STAGE = game.STAGES.RUN
		game.STATE = game.STATES.TABLE_BOARD
		game.ROOM_ATTACH = game.ROOM_ATTACH or { T = { x = 0, y = 0, w = 20, h = 11 } }
		game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
			type = "hand",
			card_limit = 7,
			selection_limit = 1,
		})
		game.dealt_letters.states = game.dealt_letters.states or {}
		game.dealt_letters.states.visible = true
		game.pattern_row = {
			area = {
				T = { x = 0, y = 0, w = 8, h = 1 },
				cards = {},
				config = { type = "placement" },
			},
		}
		mock_env.publish_game({ word_round = base_wr(), word_score_animating = false })
		return game
	end

	T.it("registers play_placement_word on the Panel callback registry", function()
		require("word_game.ui.callbacks.table_controls")
		T.assert_not_nil(Funcs.get("play_placement_word"))
	end)

	T.it("sync keeps the play button clickable during jumble play", function()
		install_table_board()
		WORD_GAME_UI = WORD_GAME_UI or {}
		WORD_GAME_UI.TableControls = require("word_game.ui.table.controls")
		WORD_GAME_UI.PlayHoldRedraw = { consume_click = function() return false end }

		WORD_GAME_UI.TableControls.ensure()
		WORD_GAME_UI.TableControls.sync()

		local play_btn = WORD_GAME_UI.TableControls.play_button_uie()
		T.assert_not_nil(play_btn)
		T.assert_equal(play_btn.config.button, "play_placement_word")
		T.assert_true(play_btn.states.collide.can)
		T.assert_true(play_btn.config.force_collision)
	end)

	T.it("play_placement_word runs placement before store dispatch", function()
		install_table_board()
		local placement = require("word_game.ui.table.controls.placement")
		local resolved = false
		local dispatched = false
		local resolution = require("word_game.ui.play_effects.resolution")
		local orig_resolve = resolution.resolve
		local action_dispatch = require("app.input.action_dispatch")
		local orig_dispatch = action_dispatch.dispatch_func

		resolution.resolve = function(mod)
			resolved = mod == require("word_game.model.jumble_play")
			return { kind = "invalid", err = "test" }
		end
		action_dispatch.dispatch_func = function(name)
			dispatched = name == "play_placement_word"
			return true
		end

		WORD_GAME_UI = WORD_GAME_UI or {}
		WORD_GAME_UI.TableControls = require("word_game.ui.table.controls")
		WORD_GAME_UI.PlayHoldRedraw = { consume_click = function() return false end }

		local Gameplay = require("word_game.ui.controllers.gameplay")
		Gameplay.play_placement_word()

		T.assert_true(resolved, "play handler should resolve the word")
		T.assert_true(dispatched, "store dispatch should still run after play")

		resolution.resolve = orig_resolve
		action_dispatch.dispatch_func = orig_dispatch
	end)

	T.it("placement try_play delegates to resolution when the table is idle", function()
		install_table_board()
		local placement = require("word_game.ui.table.controls.placement")
		local play = require("word_game.model.jumble_play")
		local resolved = false
		local resolution = require("word_game.ui.play_effects.resolution")
		local orig_resolve = resolution.resolve

		resolution.resolve = function(mod)
			resolved = mod == play
			return { kind = "invalid", err = "blocked" }
		end
		WORD_GAME_UI = WORD_GAME_UI or {}
		WORD_GAME_UI.PlayHoldRedraw = { consume_click = function() return false end }

		placement.try_play()
		T.assert_true(resolved)

		resolution.resolve = orig_resolve
	end)
end)
