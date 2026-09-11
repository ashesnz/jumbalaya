--[[ tests/unit/test_phase6_1_table_board.lua - Phase 6.1 TableBoard store subscription & Renderer test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local Engine = require("jumbalaya-engine")
local BoardUI = require("word_game.ui.table.board")

T.describe("Phase 6.1 TableBoard Store Subscription & Renderer", function()
	mock_env.reset_game()

	T.it("subscribes to store piles and renders via PileView and Renderer", function()
		local store = Store.new({
			piles = {
				hand = { { id = 1, letter = "A", pile_id = "hand" } },
				draw = { { id = 2, letter = "B", pile_id = "draw" } },
				pattern = {},
				bonus = {},
				discard = {},
			}
		})
		G._store = store

		T.assert_true(BoardUI.should_draw_sidebar_deck())

		local drawn = false
		local renderer = Engine.Renderer.new({
			draw_card = function(view, rect)
				drawn = true
				T.assert_equal(view.card.letter, "A")
			end
		})

		local pile_view = Engine.Views.PileView.new("hand", store:get().piles.hand, { x = 0, y = 0, w = 5, h = 1 })
		pile_view:draw(renderer)
		T.assert_true(drawn)

		G._store = nil
	end)
end)
