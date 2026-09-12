--[[ tests/unit/test_boot_simulation.lua
     Simulate full startup, run initialization, and game loop on iOS and desktop.
]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

T.describe("Full Game Boot & Run Simulation", function()
	T.it("boots and runs without errors on iOS simulation", function()
		MockEnv.setup()
		love.system = love.system or {}
		local orig_getOS = love.system.getOS
		love.system.getOS = function() return "iOS" end

		require("jumbalaya-engine.util.tables")
		require("jumbalaya-engine.util.geometry")
		require("jumbalaya-engine.object")
		_G.HEX = _G.HEX or function(hex)
			return { 1, 1, 1, 1 }
		end
		require("word_game.model.game")
		require("word_game.model.game.globals")
		require("app.callbacks.settings")
		require("app.bootstrap")
		require("jumbalaya-engine.adapters.love2d.lifecycle")
		require("jumbalaya-engine.adapters.love2d.window")

		local ok, err = pcall(function()
			_G.G = Game()
			package.loaded["app.callbacks.settings"] = nil
			require("app.callbacks.settings")
			_G.G:launch()
			Dictionary.load()
			-- Process events during title screen
			for i = 1, 10 do
				love.update(0.016)
				love.draw()
			end

			-- Verify title screen initialized cleanly
			T.assert_not_nil(G.GAME, "G.GAME must be initialized after boot")
			local word_game = require("word_game")
local Funcs = require("app.callbacks.funcs")
			T.assert_not_nil(word_game.store(), "WORD_GAME.store must be wired after boot")
			T.assert_not_nil(word_game.engine(), "WORD_GAME.engine must be wired after boot")
			T.assert_not_nil(G.STAGE, "G.STAGE must be set after boot")
			T.assert_equal(G.STAGES.MAIN_MENU, G.STAGE, "Initial boot should open to title screen stage")
			T.assert_not_nil(G.localization and G.localization.misc, "localization must load during launch")
			T.assert_equal(
				G.localization.misc.dictionary.ui_classic,
				"Classic",
				"menu labels must resolve from localization dictionary"
			)
			T.assert_equal(localize("ui_classic"), "Classic", "localize() must resolve dictionary keys")
			for _ = 1, 120 do
				love.update(0.016)
			end
			T.assert_not_nil(G.MAIN_MENU_UI, "title menu UI should appear after timeline frames")
			local function text_in_tree(node)
				if not node then return nil end
				if node.config and node.config.text then return node.config.text end
				for _, child in ipairs(node.children or {}) do
					local found = text_in_tree(child)
					if found then return found end
				end
				return nil
			end
			local classic = G.MAIN_MENU_UI:find_node_by_id("main_menu_classic")
			T.assert_not_nil(classic, "classic mode button should exist")
			T.assert_equal(text_in_tree(classic), "Classic", "main menu button label must be localized")

			-- Click Play to transition to gameplay board (Stage 1-1)
			Funcs.dispatch("begin_run")
			for i = 1, 60 do
				love.update(0.016)
				love.draw()
			end

			-- Verify transition to Stage 1-1 gameplay board
			T.assert_not_nil(G.GAME.word_round, "G.GAME.word_round must be present after starting run")
			T.assert_equal(1, G.GAME.word_round.set, "Round set should be 1")
			T.assert_equal(1, G.GAME.word_round.hand_index, "Round hand_index should be 1 (Stage 1-1)")
		end)

		if orig_getOS then
			love.system.getOS = orig_getOS
		end

		if not ok then
			print("Boot error:", err)
		end
		MockEnv.teardown_boot_pollution()
		T.assert_true(ok, "Game boot and early frames must succeed without error: " .. tostring(err))
	end)
end)
