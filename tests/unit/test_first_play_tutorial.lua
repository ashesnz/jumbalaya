--[[ tests/unit/test_first_play_tutorial.lua ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("First play tutorial", function()
	mock_env.reset_game()
	G.queue_settings_write = function() end
	_G.play_sfx = function() end

	local layout_instances = {}
	local saved_layout_view = _G.LayoutView
	_G.LayoutView = function(def)
		local inst = {
			definition = def.definition,
			config = def.config,
			selections = nil,
			under_overlay = nil,
			remove = function(self)
				self.removed = true
			end,
		}
		layout_instances[#layout_instances + 1] = inst
		return inst
	end

	local saved_character_speech = package.loaded["word_game.ui.tutorial.character_speech"]
	local saved_easing = package.loaded["app.effects.easing"]
	package.loaded["word_game.ui.tutorial.character_speech"] = {
		bubble_definition = function()
			return { n = G.UI.ROOT, config = { align = "cm" }, nodes = {} }
		end,
		pop_bubble = function() end,
	}
	package.loaded["app.effects.easing"] = {
		value = function() end,
	}
	package.loaded["word_game.ui.tutorial.first_play"] = nil

	local FirstPlayTutorial = require("word_game.ui.tutorial.first_play")
	_G.WORD_GAME = _G.WORD_GAME or {}
	WORD_GAME_UI.FirstPlayTutorial = FirstPlayTutorial
	WORD_GAME_UI.PerkStamp = { try_opening_demo = function() end }

	local function reset_env()
		layout_instances = {}
		G.FIRST_PLAY_TUTORIAL_OVERLAY = nil
		G.dealt_letters = { T = { x = 2, y = 6, w = 8, h = 1.4 } }
		G.SETTINGS = G.SETTINGS or {}
		G.SETTINGS.first_play_tutorial_complete = false
		G.SETTINGS.first_play_tutorial_force = false
		G.F_SKIP_TUTORIAL = false
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.RUN = { from_save = false, active = true }
		FirstPlayTutorial.reset()
	end

	T.it("should_show is false when F_SKIP_TUTORIAL is set", function()
		reset_env()
		G.F_SKIP_TUTORIAL = true
		T.assert_false(FirstPlayTutorial.should_show())
	end)

	T.it("should_show is false after completion unless force is on", function()
		reset_env()
		T.assert_true(FirstPlayTutorial.should_show())
		G.SETTINGS.first_play_tutorial_complete = true
		T.assert_false(FirstPlayTutorial.should_show())
		G.SETTINGS.first_play_tutorial_force = true
		T.assert_true(FirstPlayTutorial.should_show())
	end)

	T.it("begin creates welcome step with bubble only", function()
		reset_env()
		T.assert_true(FirstPlayTutorial.begin())
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_not_nil(G.FIRST_PLAY_TUTORIAL_OVERLAY)
		T.assert_equal(#G.FIRST_PLAY_TUTORIAL_OVERLAY.selections, 1)
		T.assert_nil(G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_hand)
	end)

	T.it("advance moves to hand spotlight step", function()
		reset_env()
		FirstPlayTutorial.begin()
		FirstPlayTutorial.advance()
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_equal(#G.FIRST_PLAY_TUTORIAL_OVERLAY.selections, 2)
		T.assert_true(G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_hand)
	end)

	T.it("dismiss clears overlay and marks tutorial complete", function()
		reset_env()
		FirstPlayTutorial.begin()
		FirstPlayTutorial.dismiss()
		T.assert_false(FirstPlayTutorial.is_active())
		T.assert_nil(G.FIRST_PLAY_TUTORIAL_OVERLAY)
		T.assert_true(G.SETTINGS.first_play_tutorial_complete)
	end)

	T.it("dismiss does not mark complete while force is enabled", function()
		reset_env()
		G.SETTINGS.first_play_tutorial_force = true
		FirstPlayTutorial.begin()
		FirstPlayTutorial.dismiss()
		T.assert_false(G.SETTINGS.first_play_tutorial_complete)
	end)

	T.it("consume_click advances the tutorial", function()
		reset_env()
		FirstPlayTutorial.begin()
		G.INPUT = { clicked = { handled = false }, dragging = {} }
		T.assert_true(FirstPlayTutorial.consume_click())
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_equal(#G.FIRST_PLAY_TUTORIAL_OVERLAY.selections, 2)
	end)

	T.it("advance moves to placement spotlight step", function()
		reset_env()
		FirstPlayTutorial.begin()
		FirstPlayTutorial.advance()
		FirstPlayTutorial.advance()
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_equal(#G.FIRST_PLAY_TUTORIAL_OVERLAY.selections, 1)
		T.assert_true(G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_placement)
		T.assert_nil(G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_hand)
	end)

	T.it("advance moves to play button spotlight step", function()
		reset_env()
		G.hand_action_bar = { REMOVED = false, T = { x = 12, y = 8, w = 1, h = 1 } }
		WORD_GAME_UI.TableControls = {
			sync = function() end,
			play_button_uie = function()
				return { T = { x = 12, y = 8, w = 1, h = 1 } }
			end,
		}
		FirstPlayTutorial.begin()
		for _ = 1, 4 do
			FirstPlayTutorial.advance()
		end
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_true(G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_play)
	end)

	T.it("advance moves to timeline goal spotlight step", function()
		reset_env()
		G.hand_action_bar = { REMOVED = false, T = { x = 12, y = 8, w = 1, h = 1 } }
		WORD_GAME_UI.TableControls = {
			sync = function() end,
			play_button_uie = function()
				return { T = { x = 12, y = 8, w = 1, h = 1 } }
			end,
		}
		FirstPlayTutorial.begin()
		for _ = 1, 5 do
			FirstPlayTutorial.advance()
		end
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_true(G.FIRST_PLAY_TUTORIAL_OVERLAY.redraw_timeline)
	end)

	T.it("sixth advance dismisses tutorial", function()
		reset_env()
		FirstPlayTutorial.begin()
		for _ = 1, 6 do
			FirstPlayTutorial.advance()
		end
		T.assert_false(FirstPlayTutorial.is_active())
		T.assert_true(G.SETTINGS.first_play_tutorial_complete)
	end)

	T.it("reset clears completion flag", function()
		reset_env()
		G.SETTINGS.first_play_tutorial_complete = true
		FirstPlayTutorial.reset()
		T.assert_false(G.SETTINGS.first_play_tutorial_complete)
	end)

	_G.LayoutView = saved_layout_view
	package.loaded["word_game.ui.tutorial.character_speech"] = saved_character_speech
	package.loaded["app.effects.easing"] = saved_easing
end)
