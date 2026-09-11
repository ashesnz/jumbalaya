--[[
	word_game/ui/views/table_controls_view.lua - Play/shuffle action bar hosts (Phase 8).
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Panels = require("jumbalaya-engine.panels")

local TableControlsView = {}
TableControlsView.__index = TableControlsView

local function delegate_index(view, key)
	local own = TableControlsView[key]
	if own ~= nil then return own end
	local inner = view._inner
	if inner then return inner[key] end
	return nil
end

local function wrap_bar(inner)
	local view = setmetatable({
		_inner = inner,
	}, TableControlsView)
	setmetatable(view, { __index = function(t, k) return delegate_index(t, k) end })
	view.T = inner.T
	view.VT = inner.VT
	view.root_node = inner.root_node
	view.config = inner.config
	view.REMOVED = inner.REMOVED
	return view
end

function TableControlsView.create_bar(button_def, size, config)
	local inner = Panels.create({
		definition = {
			n = runtime().UI.ROOT,
			config = { align = "cm", colour = runtime().C.CLEAR, minw = size, minh = size },
			nodes = { button_def },
		},
		config = config or {
			align = "cm",
			major = runtime().ROOM_ATTACH,
			offset = { x = 0, y = 0 },
		},
	})
	return wrap_bar(inner)
end

function TableControlsView.create_shuffle_bar(size, config)
	local definition = require("word_game.ui.table.controls.definition")
	return TableControlsView.create_bar(definition.shuffle_button_def(size), size, config)
end

function TableControlsView.create_play_bar(size, config)
	local definition = require("word_game.ui.table.controls.definition")
	return TableControlsView.create_bar(definition.play_button_def(size), size, config)
end

function TableControlsView:draw()
	if self._inner then
		self._inner:draw()
	end
end

function TableControlsView:recalculate()
	if not self._inner then return end
	self._inner:recalculate()
	self.T = self._inner.T
	self.VT = self._inner.VT
	self.root_node = self._inner.root_node
	self.config = self._inner.config
	self.REMOVED = self._inner.REMOVED
end

function TableControlsView:remove()
	if self._inner and self._inner.remove then
		self._inner:remove()
	end
	self._inner = nil
	self.REMOVED = true
end

function TableControlsView:find_node_by_id(id)
	if self._inner and self._inner.find_node_by_id then
		return self._inner:find_node_by_id(id)
	end
	return nil
end

return TableControlsView
