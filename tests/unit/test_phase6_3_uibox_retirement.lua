--[[ tests/unit/test_phase6_3_uibox_retirement.lua - Phase 6.3 UIBox retirement & TableBoard store rendering test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local Engine = require("jumbalaya-engine")
local BoardUI = require("word_game.ui.table.board")

T.describe("Phase 6.3 UIBox Retirement & TableBoard Store Rendering", function()
	mock_env.reset_game()

	T.it("ensures G.LIVE.UIBOX is retired and absent", function()
		T.assert_nil(G.LIVE.UIBOX)
	end)

	T.it("renders TABLE_BOARD piles from store store state", function()
		local store = Store.new({
			piles = {
				hand = { { id = 1, letter = "C", pile_id = "hand" } },
				draw = { { id = 2, letter = "D", pile_id = "draw" } },
				pattern = {},
				bonus = {},
				discard = {},
			}
		})
		G._store = store

		T.assert_true(BoardUI.should_draw_sidebar_deck())

		local hand_drawn = false
		local renderer = Engine.Renderer.new({
			draw_card = function(view, rect)
				hand_drawn = true
				T.assert_equal(view.card.letter, "C")
			end
		})

		local pile_view = Engine.Views.PileView.new("hand", store:get().piles.hand, { x = 0, y = 0, w = 5, h = 1 })
		pile_view:draw(renderer)
		T.assert_true(hand_drawn)

		G._store = nil
	end)
end)
