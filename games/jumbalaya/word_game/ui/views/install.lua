--[[
	word_game/ui/views/install.lua - Phase 6 view components subscribed to store.
]]

local Engine = require("jumbalaya-engine")
local TableBoardView = require("word_game.ui.views.table_board_view")
local SidebarView = require("word_game.ui.views.sidebar_view")
local TradeView = require("word_game.ui.views.trade_view")

local M = {
	_table_board_view = nil,
	_sidebar_view = nil,
	_trade_view = nil,
}

function M.install_table_board(engine)
	if not engine or not engine.store then return end
	local store = engine.store
	if not M._table_board_view then
		M._table_board_view = TableBoardView.new({ renderer = engine.renderer or Engine.Renderer.love2d() })
	end
	M._table_board_view:bind_store(store)
end

function M.install_sidebar(engine)
	if not engine or not engine.store then return end
	local store = engine.store
	if not M._sidebar_view then
		M._sidebar_view = SidebarView.new({ store = store })
	else
		M._sidebar_view:bind_store(store)
	end
end

function M.install_trade(engine)
	if not engine or not engine.store then return end
	local store = engine.store
	if not M._trade_view then
		M._trade_view = TradeView.new({ store = store })
	else
		M._trade_view:bind_store(store)
	end
end

function M.install(engine)
	M.install_table_board(engine)
end

function M.reset()
	M._table_board_view = nil
	M._sidebar_view = nil
	M._trade_view = nil
end

function M.table_board_view()
	return M._table_board_view
end

function M.sidebar_view()
	return M._sidebar_view
end

function M.trade_view()
	return M._trade_view
end

return M
