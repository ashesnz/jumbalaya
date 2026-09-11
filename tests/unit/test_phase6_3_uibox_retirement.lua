--[[ tests/unit/test_phase6_3_uibox_retirement.lua - Phase 6.3 UIBox retirement & TableBoard store rendering test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local Engine = require("jumbalaya-engine")
local BoardUI = require("word_game.ui.table.board")
local views_install = require("word_game.ui.views.install")

T.describe("Phase 6.3 UIBox Retirement & TableBoard Store Rendering", function()
	mock_env.reset_game()
	views_install.reset()

	T.it("ensures G.LIVE.UIBOX is retired and absent", function()
		T.assert_nil(G.LIVE.UIBOX)
	end)

	T.it("renders TABLE_BOARD piles from store via TableBoardView", function()
		local store = Store.new({
			piles = {
				hand = { { id = 1, letter = "C", pile_id = "hand" } },
				draw = { { id = 2, letter = "D", pile_id = "draw" } },
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		G._store = store
		G._engine = Engine.Context.new({ store = store })
		G.dealt_letters = { cards = {}, T = { x = 0, y = 0, w = 5, h = 1 } }

		views_install.install_table_board(G._engine)
		local table_view = BoardUI.table_board_view()
		T.assert_not_nil(table_view)
		T.assert_true(table_view:should_render_hand_from_store())

		local hand_drawn = false
		local renderer = Engine.Renderer.new({
			draw_card = function(view, rect)
				hand_drawn = true
				T.assert_equal(view.card.letter, "C")
			end,
		})
		table_view:draw_hand(renderer)
		T.assert_true(hand_drawn)

		G._store = nil
		G._engine = nil
	end)
end)
