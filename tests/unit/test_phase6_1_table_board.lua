--[[ tests/unit/test_phase6_1_table_board.lua - Phase 6.1 TableBoard store subscription & Renderer test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local Engine = require("jumbalaya-engine")
local BoardUI = require("word_game.ui.table.board")
local views_install = require("word_game.ui.views.install")

T.describe("Phase 6.1 TableBoard Store Subscription & Renderer", function()
	mock_env.reset_game()
	views_install.reset()

	T.it("subscribes to store piles and renders via TableBoardView", function()
		local store = Store.new({
			piles = {
				hand = { { id = 1, letter = "A", pile_id = "hand" } },
				draw = { { id = 2, letter = "B", pile_id = "draw" } },
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		G._store = store
		G._engine = Engine.Context.new({ store = store })
		G.dealt_letters = { cards = {}, T = { x = 1, y = 2, w = 5, h = 1 } }

		views_install.install_table_board(G._engine)
		local table_view = BoardUI.ensure_store_subscription()
		T.assert_not_nil(table_view)

		local revision_before = table_view:revision()
		store:dispatch({ type = "MOVE_CARD", card_id = 1, to_pile = "hand", slot = 1 })
		T.assert_true(table_view:revision() > revision_before)
		T.assert_true(table_view:should_render_hand_from_store())

		local drawn = false
		local renderer = Engine.Renderer.new({
			draw_card = function(view, rect)
				drawn = true
				T.assert_equal(view.card.letter, "A")
			end,
		})
		table_view:draw_hand(renderer)
		T.assert_true(drawn)

		G._store = nil
		G._engine = nil
	end)

	T.it("prefers store draw pile when legacy draw pile is empty", function()
		local store = Store.new({
			piles = {
				hand = {},
				draw = { { id = 2, letter = "B", pile_id = "draw" } },
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		G._store = store
		G._engine = Engine.Context.new({ store = store })
		G.draw_pile = { cards = {}, T = { x = 0, y = 0, w = 1, h = 1 } }

		views_install.install_table_board(G._engine)
		local table_view = BoardUI.table_board_view()
		T.assert_true(table_view:should_render_draw_from_store())

		G._store = nil
		G._engine = nil
	end)
end)
