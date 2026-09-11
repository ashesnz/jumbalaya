--[[ tests/unit/test_token_reward_fly.lua - Token reward fly animation integration ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Token reward fly animation", function()
	T.it("awards tokens after flyers complete on a classic hand", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.GAME.run_state = { tokens = 0, perks = {} }
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			jumble = { total_score = 18 },
		}
		G.TILESCALE = 1
		G.TILESIZE = 71
		G.TEXTURE_ATLASES = G.TEXTURE_ATLASES or {}
		G.TEXTURE_ATLASES.coin = {
			px = 4,
			py = 4,
			image = { getDimensions = function() return 4, 4 end },
		}

		local Layout = require("word_game.ui.layout")
		local TokenReward = require("word_game.ui.table.token_reward")
		local timeline = {
			is_active = false,
			time_remaining = 0,
			freeze_reward_display = function() end,
		}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME_UI.Layout = Layout
		WORD_GAME_UI.TimelineTimer = timeline
		WORD_GAME_UI.TableDeck = {
			token_center_px = function() return 400, 300 end,
			bump_token_display = function() end,
		}

		local started = TokenReward.try_award(function() end)
		T.assert_true(started)
		T.assert_true(TokenReward.is_active())

		for _ = 1, 200 do
			TokenReward.update(0.05)
			if not TokenReward.is_active() then break end
		end

		T.assert_false(TokenReward.is_active(), "Token fly animation should finish")
		T.assert_true((G.GAME.run_state.tokens or 0) > 0, "Tokens should be granted after flyers land")
	end)
end)
