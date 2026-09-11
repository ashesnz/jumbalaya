--[[
	word_game/ui/views/sidebar_view.lua - Sidebar HUD store subscription (Phase 6).
]]

local SidebarView = {}
SidebarView.__index = SidebarView

local function sidebar_signature(state)
	if not state then return nil end
	local rs = state.run_state
	local wr = state.word_round
	return string.format(
		"%s|%s|%s|%s",
		tostring(rs and rs.tokens),
		tostring(rs and rs.match_over),
		tostring(wr and wr.set),
		tostring(wr and wr.hand_index)
	)
end

function SidebarView.new(store)
	local view = setmetatable({
		store = store,
		_signature = nil,
		_revision = 0,
	}, SidebarView)
	if store then
		view:bind_store(store)
	end
	return view
end

function SidebarView:bind_store(store)
	self.store = store
	if not store then return end
	if self._subscribed_store == store then return end
	self._subscribed_store = store
	store:subscribe(function(state)
		local sig = sidebar_signature(state)
		if self._signature == sig then return end
		self._signature = sig
		self._revision = (self._revision or 0) + 1
	end)
	self._signature = sidebar_signature(store:get())
end

function SidebarView:revision()
	return self._revision or 0
end

function SidebarView:signature()
	return self._signature
end

return SidebarView
