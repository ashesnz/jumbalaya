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

		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("app.core.object")
		_G.HEX = _G.HEX or function(hex)
			return { 1, 1, 1, 1 }
		end
		require("word_game.model.game")
		require("word_game.model.globals")
		require("app.callbacks.settings")
		require("app.bootstrap")
		require("app.core.session.lifecycle")
		require("app.core.platform.window")

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
			T.assert_not_nil(G.STAGE, "G.STAGE must be set after boot")
			T.assert_equal(G.STAGES.MAIN_MENU, G.STAGE, "Initial boot should open to title screen stage")

			-- Click Play to transition to gameplay board (Stage 1-1)
			G.FUNCS.begin_run()
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
