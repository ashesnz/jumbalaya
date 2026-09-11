--[[
	word_game/ui/views/trade_view.lua - Trade overlay store subscription (Phase 6).
]]

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

function TradeView.new(store)
	local view = setmetatable({
		store = store,
		_signature = nil,
		_revision = 0,
	}, TradeView)
	if store then
		view:bind_store(store)
	end
	return view
end

function TradeView:bind_store(store)
	self.store = store
	if not store then return end
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

return TradeView
