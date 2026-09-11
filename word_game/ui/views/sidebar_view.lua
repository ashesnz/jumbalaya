--[[
	word_game/ui/views/sidebar_view.lua - Sidebar HUD store-backed view (Phase 6 / 8).
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Engine = require("jumbalaya-engine")
local Layout = require("word_game.ui.layout")
local hud_layout = require("word_game.ui.sidebar.hud_layout")
local table_discard = require("word_game.ui.perks.discard_bin")
local stage_button = require("word_game.ui.sidebar.stage_button")
local facade = require("word_game.ui.facade")

local SidebarView = {}
SidebarView.__index = SidebarView

local function sidebar_signature(state)
	if not state then return nil end
	local rs = state.run_state
	local wr = state.word_round
	return string.format(
		"%s|%s|%s|%s|%s",
		tostring(rs and rs.tokens),
		tostring(rs and rs.match_over),
		tostring(wr and wr.set),
		tostring(wr and wr.hand_index),
		tostring(state.deck_left_count)
	)
end

local function tile_scale()
	return (runtime().TILESCALE or 1) * (runtime().TILESIZE or 20)
end

local function font_metrics()
	local lang = (runtime() and runtime().LANG) or {}
	local font_obj = lang.font or {}
	return {
		face = font_obj.FONT,
		font_scale = font_obj.FONTSCALE or 0.12,
		squish = font_obj.squish or 1,
		height_scale = font_obj.TEXT_HEIGHT_SCALE or 0.7,
	}
end

local function text_box_size(text, scale)
	local metrics = font_metrics()
	local tile = tile_scale()
	local text_w = (metrics.face and metrics.face.getWidth and metrics.face:getWidth(text))
		or (string.len(text or "") * 10)
	local text_h = (metrics.face and metrics.face.getHeight and metrics.face:getHeight()) or 20
	local px_w = text_w * metrics.squish * scale * (runtime().TILESCALE or 1) * metrics.font_scale
	local px_h = text_h * scale * (runtime().TILESCALE or 1) * metrics.font_scale * metrics.height_scale
	return px_w / tile, px_h / tile
end

local function make_text_proxy(id, rect, text)
	local proxy = {
		config = {
			id = id,
			text = text,
			scale = hud_layout.SIDEBAR_COUNTER_SCALE,
			colour = (runtime() and runtime().C and runtime().C.UI and runtime().C.UI.TEXT_LIGHT) or { 1, 1, 1, 1 },
			shadow = true,
		},
		T = { x = rect.x, y = rect.y, w = rect.w, h = rect.h },
		VT = { x = rect.x, y = rect.y, w = rect.w, h = rect.h },
	}
	function proxy:update_text()
		local value = self.config.text
		if self.config.ref_table and self.config.ref_value then
			value = self.config.ref_table[self.config.ref_value]
		end
		self.config.text = tostring(value or 0)
		self.config.text_drawable = self.config.text
	end
	return proxy
end

local function make_button_proxy(layout)
	local rect = layout.end_button
	local label_text = stage_button.current_label and stage_button.current_label() or "End Run"
	local label = make_text_proxy("end_run_label", {
		x = rect.x,
		y = rect.y,
		w = rect.w,
		h = rect.h,
	}, label_text)
	label.config.scale = stage_button.label_scale_for(label_text)
	local button = {
		config = {
			id = "end_run_button",
			button = stage_button.current_action and stage_button.current_action() or "end_run_from_sidebar",
			colour = stage_button.current_colour and stage_button.current_colour() or ((runtime() and runtime().C and runtime().C.RED) or { 1, 0, 0.4, 1 }),
			minw = rect.w,
			minh = rect.h,
			maxw = rect.w,
			maxh = rect.h,
			visible = hud_layout.end_run_button_visible(),
			padding = 0,
			align = "cm",
		},
		states = { visible = hud_layout.end_run_button_visible() },
		T = { x = rect.x, y = rect.y, w = rect.w, h = rect.h, r = 0 },
		VT = { x = rect.x, y = rect.y, w = rect.w, h = rect.h, r = 0 },
		children = { label },
		nodes = { label },
	}
	label.parent = button
	return button, label
end

function SidebarView.new(opts)
	opts = opts or {}
	local view = setmetatable({
		store = opts.store,
		renderer = opts.renderer or Engine.Renderer.love2d(),
		_state = nil,
		_revision = 0,
		_layout = nil,
		_button_proxy = nil,
		_label_proxy = nil,
		_deck_count_proxy = nil,
		_label_proxy_node = nil,
	}, SidebarView)
	if opts.store then
		view:bind_store(opts.store)
	end
	return view
end

function SidebarView:bind_store(store)
	self.store = store
	if not store then return end
	if self._subscribed_store ~= store then
		self._subscribed_store = store
		store:subscribe(function(state)
			self._state = state
			local sig = sidebar_signature(state)
			if self._signature ~= sig then
				self._signature = sig
				self._revision = (self._revision or 0) + 1
			end
		end)
	end
	self._state = store:get()
	self._signature = sidebar_signature(self._state)
end

function SidebarView:revision()
	return self._revision or 0
end

function SidebarView:signature()
	return self._signature
end

function SidebarView:state()
	return self._state or (self.store and self.store:get())
end

function SidebarView:deck_left_count()
	if runtime() and runtime().ARGS and runtime().ARGS.deck_left_count ~= nil then
		return runtime().ARGS.deck_left_count
	end
	local state = self:state()
	return state and state.deck_left_count or 0
end

function SidebarView:relayout()
	Layout.update_sidebar_attach()
	self._layout = hud_layout.compute()
	local button, label = make_button_proxy(self._layout)
	self._button_proxy = button
	self._label_proxy = label
	local count_rect = self._layout.deck_count
	self._deck_count_proxy = make_text_proxy("text_deck_count", count_rect, tostring(self:deck_left_count()))
	self._deck_count_proxy.config.ref_table = runtime() and runtime().ARGS
	self._deck_count_proxy.config.ref_value = "deck_left_count"
	stage_button.bind_button_proxy(button, label)
	return self._layout
end

function SidebarView:recalculate()
	return self:relayout()
end

function SidebarView:layout()
	if not self._layout then
		self:relayout()
	end
	return self._layout
end

function SidebarView:find_node_by_id(id)
	if id == "end_run_button" then return self._button_proxy end
	if id == "end_run_label" then return self._label_proxy end
	if id == "text_deck_count" then
		if self._deck_count_proxy then
			self._deck_count_proxy.config.text = tostring(self:deck_left_count())
		end
		return self._deck_count_proxy
	end
	local rect = hud_layout.slot_rect(self:layout(), id)
	if not rect then return nil end
	return {
		config = { id = id },
		T = { x = rect.x, y = rect.y, w = rect.w, h = rect.h },
		VT = { x = rect.x, y = rect.y, w = rect.w, h = rect.h },
	}
end

function SidebarView:sync_end_run_row()
	table_discard.sync_discard_pile_area()
	if stage_button.sync then
		stage_button.sync()
	end
	self:relayout()
end

function SidebarView:remove()
	self._layout = nil
	self._button_proxy = nil
	self._label_proxy = nil
	self._deck_count_proxy = nil
	stage_button.bind_button_proxy(nil, nil)
end

local function draw_panel(rect)
	local colour = (runtime() and runtime().C and runtime().C.DYN_UI and runtime().C.DYN_UI.MAIN) or { 0.22, 0.32, 0.35, 1 }
	love.graphics.setColor(colour)
	love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h)
end

local function draw_counter_row(rect, count)
	local label = "Cards left: "
	local scale = hud_layout.SIDEBAR_COUNTER_SCALE
	local colour = (runtime() and runtime().C and runtime().C.UI and runtime().C.UI.TEXT_LIGHT) or { 1, 1, 1, 1 }
	local label_w = text_box_size(label, scale)
	local value_w = text_box_size(tostring(count), scale)
	local total_w = label_w + value_w
	local x = rect.x + math.max(0, (rect.w - total_w) * 0.5)
	local y = rect.y + math.max(0, (rect.h - text_box_size("0", scale)) * 0.5)
	love.graphics.setColor(colour)
	love.graphics.print(label, x, y, 0, scale * (runtime().TILESCALE or 1))
	love.graphics.print(tostring(count), x + label_w, y, 0, scale * (runtime().TILESCALE or 1))
end

function SidebarView:draw(renderer)
	if not runtime() or runtime().STAGE ~= runtime().STAGES.RUN then return end
	if not hud_layout.end_run_button_visible() then return end
	local layout = self:layout()
	self._deck_count_proxy = self._deck_count_proxy or self:find_node_by_id("text_deck_count")
	stage_button.sync()
	stage_button.draw(layout.end_button)
	draw_panel(layout.panel)
	draw_counter_row(layout.deck_count, self:deck_left_count())
end

function SidebarView:consume_click(mx, my)
	return stage_button.consume_click(mx, my, self:layout().end_button)
end

function SidebarView:ensure_deck_count()
	local deck = facade.deck()
	if deck and deck.sync_deck_count_display then
		deck.sync_deck_count_display()
	end
end

return SidebarView
