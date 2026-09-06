--[[ tests/unit/test_first_play_tutorial.lua ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("First play tutorial", function()
	mock_env.setup()
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

	local saved_character_speech = package.loaded["word_game.ui.character_speech"]
	local saved_easing = package.loaded["app.effects.easing"]
	package.loaded["word_game.ui.character_speech"] = {
		bubble_definition = function()
			return { n = G.UI.ROOT, config = { align = "cm" }, nodes = {} }
		end,
		pop_bubble = function() end,
	}
	package.loaded["app.effects.easing"] = {
		value = function() end,
	}
	package.loaded["word_game.ui.first_play_tutorial"] = nil

	local FirstPlayTutorial = require("word_game.ui.first_play_tutorial")
	_G.WORD_GAME = _G.WORD_GAME or {}
	WORD_GAME.FirstPlayTutorial = FirstPlayTutorial
	WORD_GAME.PerkStamp = { try_opening_demo = function() end }

	local function reset_env()
		layout_instances = {}
		G.FIRST_PLAY_TUTORIAL_OVERLAY = nil
		G.SETTINGS = G.SETTINGS or {}
		G.SETTINGS.first_play_tutorial_complete = false
		G.SETTINGS.first_play_tutorial_force = false
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.RUN = { from_save = false, active = true }
		FirstPlayTutorial.reset()
	end

	T.it("should_show is false after completion unless force is on", function()
		reset_env()
		T.assert_true(FirstPlayTutorial.should_show())
		G.SETTINGS.first_play_tutorial_complete = true
		T.assert_false(FirstPlayTutorial.should_show())
		G.SETTINGS.first_play_tutorial_force = true
		T.assert_true(FirstPlayTutorial.should_show())
	end)

	T.it("begin creates a dim overlay and marks active", function()
		reset_env()
		T.assert_true(FirstPlayTutorial.begin())
		T.assert_true(FirstPlayTutorial.is_active())
		T.assert_not_nil(G.FIRST_PLAY_TUTORIAL_OVERLAY)
		T.assert_equal(#G.FIRST_PLAY_TUTORIAL_OVERLAY.selections, 2)
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

	T.it("advance dismisses on the final step", function()
		reset_env()
		FirstPlayTutorial.begin()
		G.FUNCS.first_play_tutorial_next()
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
	package.loaded["word_game.ui.character_speech"] = saved_character_speech
	package.loaded["app.effects.easing"] = saved_easing
end)
