--[[
	word_game/ui/views/trade_view.lua - Trade overlay store subscription + marketplace body host (Phase 6 / 8).
]]

local Panels = require("jumbalaya-engine.panels")

local TradeView = {}
TradeView.__index = TradeView

local function trade_signature(state)
	if not state then return nil end
	local rs = state.run_state
	return string.format(
		"%s|%s",
		tostring(rs and rs.trade_used_this_hand),
		tostring(state.last_trade_action)
	)
end

local function delegate_index(view, key)
	local own = TradeView[key]
	if own ~= nil then return own end
	local inner = view._inner
	if inner then return inner[key] end
	return nil
end

--- Marketplace body host: wraps retained panel in the views layer.
function TradeView.create_marketplace_body(ctx, config, definition)
	local trade_definition = require("word_game.ui.trade.definition")
	local inner = Panels.create({
		definition = definition or trade_definition.marketplace_body_definition(ctx),
		config = config or { offset = { x = 0, y = 0 }, align = "cm" },
	})
	local view = setmetatable({
		_inner = inner,
		store = nil,
		_signature = nil,
		_revision = 0,
	}, TradeView)
	setmetatable(view, { __index = function(t, k) return delegate_index(t, k) end })
	view.T = inner.T
	view.VT = inner.VT
	view.root_node = inner.root_node
	return view
end

function TradeView.new(opts)
	opts = opts or {}
	local store = opts.store or opts
	local view = setmetatable({
		_inner = nil,
		store = store,
		_signature = nil,
		_revision = 0,
	}, TradeView)
	if store and store.get then
		view:bind_store(store)
	end
	return view
end

function TradeView:bind_store(store)
	self.store = store
	if not store or not store.get then return end
	if self._subscribed_store == store then return end
	self._subscribed_store = store
	store:subscribe(function(state)
		local sig = trade_signature(state)
		if self._signature == sig then return end
		self._signature = sig
		self._revision = (self._revision or 0) + 1
	end)
	self._signature = trade_signature(store:get())
end

function TradeView:revision()
	return self._revision or 0
end

function TradeView:signature()
	return self._signature
end

function TradeView:draw()
	if self._inner then
		self._inner:draw()
	end
end

function TradeView:recalculate()
	if not self._inner then return end
	self._inner:recalculate()
	self.T = self._inner.T
	self.VT = self._inner.VT
	self.root_node = self._inner.root_node
end

function TradeView:remove()
	if self._inner and self._inner.remove then
		self._inner:remove()
	end
	self._inner = nil
end

function TradeView:find_node_by_id(id)
	if self._inner and self._inner.find_node_by_id then
		return self._inner:find_node_by_id(id)
	end
	return nil
end

return TradeView
