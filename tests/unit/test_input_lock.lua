--[[ tests/unit/test_input_lock.lua - Shared gameplay input gates ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local InputLock = require("word_game.model.run.input_lock")
local BonusStack = require("word_game.model.jumble.bonus_stack")

T.describe("InputLock.is_table_busy", function()
	T.it("blocks while bonus gutter cards are animating", function()
		mock_env.reset_game()
		BonusStack.clear()
		T.assert_false(InputLock.is_table_busy())
		BonusStack.set_animating(true)
		T.assert_true(InputLock.is_table_busy())
		BonusStack.set_animating(false)
		T.assert_false(InputLock.is_table_busy())
	end)

	T.it("blocks while trade marketplace card is flying", function()
		mock_env.reset_game()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TradeUI = {
			is_flying = function() return true end,
			is_transforming = function() return false end,
		}
		T.assert_true(InputLock.is_table_busy())
		WORD_GAME.TradeUI.is_flying = function() return false end
		T.assert_false(InputLock.is_table_busy())
	end)

	T.it("blocks while trade marketplace transform is running", function()
		mock_env.reset_game()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TradeUI = {
			is_flying = function() return false end,
			is_transforming = function() return true end,
		}
		T.assert_true(InputLock.is_table_busy())
	end)

	T.it("blocks while token reward flyers are active", function()
		mock_env.reset_game()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TokenReward = { is_active = function() return true end }
		T.assert_true(InputLock.is_table_busy())
		WORD_GAME.TokenReward.is_active = function() return false end
		T.assert_false(InputLock.is_table_busy())
	end)

	T.it("blocks while played cards are flying off", function()
		mock_env.reset_game()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.CardFlyOff = { is_active = function() return true end }
		T.assert_true(InputLock.is_table_busy())
		WORD_GAME.CardFlyOff.is_active = function() return false end
		T.assert_false(InputLock.is_table_busy())
	end)
end)
