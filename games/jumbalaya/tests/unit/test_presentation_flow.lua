--[[ tests/unit/test_presentation_flow.lua - Model→UI presentation bus contract ]]

local mock_env = require("tests.helpers.mock_env")
local Presentation = require("word_game.model.presentation")

local T = require("tests.framework")

T.describe("presentation flow", function()
	mock_env.reset_game()

	local preview_enabled
	local hud_snaps = 0
	mock_env.install_presentation({
		ScoreBanner = {
			state = function() return { remaining = 0, target = 20, to_go_label = "SCORE" } end,
			snap_to_actual = function()
				hud_snaps = hud_snaps + 1
			end,
			sync_points_to_get_preview = function(enabled)
				preview_enabled = enabled
			end,
		},
	})

	T.it("PLAY_RESOLVED enables preview and refreshes jumble HUD", function()
		preview_enabled = nil
		hud_snaps = 0
		Presentation.emit("PLAY_RESOLVED", {
			kind = "word_play",
			old_score = 0,
			new_score = 3,
		})
		T.assert_equal(preview_enabled, true)
		T.assert_equal(hud_snaps, 1)
	end)

	T.it("PLAY_RESOLVED ignores invalid plays", function()
		preview_enabled = nil
		hud_snaps = 0
		Presentation.emit("PLAY_RESOLVED", { kind = "invalid", err = "empty" })
		T.assert_nil(preview_enabled)
		T.assert_equal(hud_snaps, 0)
	end)

	T.it("jumble_hud_refresh snaps score banner from model state", function()
		local snaps = 0
		require("word_game.ui.presentation.install").install({
			ScoreBanner = {
				snap_to_actual = function() snaps = snaps + 1 end,
			},
		})
		Presentation.emit("jumble_hud_refresh")
		T.assert_equal(snaps, 1)
	end)
end)
