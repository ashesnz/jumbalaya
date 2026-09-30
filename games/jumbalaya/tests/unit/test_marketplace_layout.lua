--[[ tests/unit/test_marketplace_layout.lua - Marketplace body is a real panel sized like working-version ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

T.describe("marketplace layout", function()
	T.it("hosts the marketplace body as a retained panel with the working-version card-row footprint", function()
		mock_env.setup()
		mock_env.ensure_card_class()
		require("word_game.ui.widgets.buttons")
		local game = shell.game()
		game.CARD_W = game.CARD_W or 1.4
		game.CARD_H = game.CARD_H or 1.9
		game.TILESIZE = game.TILESIZE or 64
		game.TILESCALE = game.TILESCALE or 1
		game.UI = game.UI or {
			TEXT = 1, BOX = 2, COLUMN = 3, ROW = 4, OBJECT = 5, ROOT = 7, padding = 0,
		}
		game.C = game.C or {}
		game.C.CLEAR = game.C.CLEAR or { 0, 0, 0, 0 }
		game.C.BLUE = game.C.BLUE or { 0.2, 0.4, 1, 1 }
		game.C.RED = game.C.RED or { 1, 0.2, 0.2, 1 }
		game.C.GOLD = game.C.GOLD or { 1, 0.85, 0.2, 1 }
		game.C.WHITE = game.C.WHITE or { 1, 1, 1, 1 }
		game.C.BLACK = game.C.BLACK or { 0, 0, 0, 1 }
		game.C.UI = game.C.UI or {}
		game.C.UI.BUTTON = game.C.UI.BUTTON or { 0.3, 0.3, 0.3, 1 }
		game.C.UI.BUTTON_HOVER = game.C.UI.BUTTON_HOVER or { 0.4, 0.4, 0.4, 1 }
		game.C.UI.BUTTON_TEXT = game.C.UI.BUTTON_TEXT or { 1, 1, 1, 1 }
		game.C.UI.BACKGROUND_INACTIVE = game.C.UI.BACKGROUND_INACTIVE or { 0.2, 0.2, 0.2, 1 }

		local offer = {
			add = {
				letters = {
					{ letter = "A", color = "red" },
					{ letter = "E", color = "red" },
					{ letter = "R", color = "red" },
				},
			},
		}
		local ctx = {
			host = {
				session_add_cost = function() return 10 end,
				is_action_disabled = function() return true end,
			},
			get_offer = function() return offer end,
			get_session = function()
				return { add_done = false, remove_done = true, modified = {} }
			end,
			modal_minh = function() return 8 end,
		}

		local TradeView = require("word_game.ui.views.trade_view")
		local def = require("word_game.ui.trade.definition")
		local body = TradeView.create_marketplace_body(ctx)

		T.assert_nil(rawget(body, "_inner"), "marketplace body must be the panel, not a proxy wrapper")
		T.assert_not_nil(body.T)
		T.assert_not_nil(body.root_node)
		local minw = 3.8 * game.CARD_W * def.MARKET_CARD_SCALE
		T.assert_true(body.T.w + 1e-6 >= minw, "body width should reserve the three-card row")
		local live = game.LIVE and game.LIVE.UIBOX
		if live then
			for _, panel in ipairs(live) do
				T.assert_true(panel ~= body, "embedded marketplace body must not register in LIVE.UIBOX")
			end
		end
		if body.remove then
			body:remove()
		end
	end)
end)
