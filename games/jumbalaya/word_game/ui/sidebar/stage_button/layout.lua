--[[ word_game/ui/sidebar/stage_button/layout.lua - Label metrics and HUD proxy wiring ]]

local game = require("word_game.ui.util.game_runtime").game
local Layout = require("word_game.ui.layout")
local state = require("word_game.ui.sidebar.stage_button.state")

local M = {}


local function widget()
	return state.widget()
end

function M.font_metrics()
	local lang = (game() and game().LANG) or {}
	local font_obj = lang.font or {}
	return {
		face = font_obj.FONT,
		font_scale = font_obj.FONTSCALE or 0.12,
		squish = font_obj.squish or 1,
		height_scale = font_obj.TEXT_HEIGHT_SCALE or 0.7,
	}
end

function M.text_box_size(text, scale)
	local metrics = M.font_metrics()
	local tile = (game().TILESIZE or 20) * (game().TILESCALE or 1)
	local text_w = (metrics.face and metrics.face.getWidth and metrics.face:getWidth(text))
		or (string.len(text or "") * 10)
	local text_h = (metrics.face and metrics.face.getHeight and metrics.face:getHeight())
		or 20
	local px_w = text_w * metrics.squish * scale * (game().TILESCALE or 1) * metrics.font_scale
	local px_h = text_h * scale * (game().TILESCALE or 1) * metrics.font_scale * metrics.height_scale
	return px_w / tile, px_h / tile
end

local function label_scale_for(text, btn_side)
	local max_w = (btn_side or 0.62) * 0.9
	local max_h = (btn_side or 0.62) * 0.9
	local scale = 0.34
	local w, h = M.text_box_size(text, scale)
	if w > max_w or h > max_h then
		local w_scale = w > 0 and (scale * max_w / w) or scale
		local h_scale = h > 0 and (scale * max_h / h) or scale
		scale = math.min(w_scale, h_scale)
	end
	return math.max(0.14, scale)
end

function M.label_scale_for(text)
	local dw, dh = Layout.end_run_slot_size()
	return label_scale_for(text, math.min(dw, dh))
end

function M.red_colour()
	return (game() and game().C and game().C.RED) or { 1, 0, 0.4, 1 }
end

function M.blue_colour()
	return (game() and game().C and game().C.BLUE) or { 0.2, 0.5, 1, 1 }
end

function M.label_colour()
	return (game() and game().C and game().C.UI and game().C.UI.TEXT_LIGHT) or { 1, 1, 1, 1 }
end

local function find_node(uie, id)
	if not uie then return nil end
	if uie.config and uie.config.id == id then return uie end
	for _, child in pairs(uie.children or {}) do
		local found = find_node(child, id)
		if found then return found end
	end
	return nil
end

function M.button_column()
	if state.bound_button() then return state.bound_button() end
	if game().SIDEBAR_HUD and game().SIDEBAR_HUD.find_node_by_id then
		return game().SIDEBAR_HUD:find_node_by_id("end_run_button")
	end
	return nil
end

function M.label_node(col)
	if state.bound_label() and col == state.bound_button() then
		return state.bound_label()
	end
	return find_node(col, "end_run_label")
end

function M.set_button_rotation(col, radians)
	local w = widget()
	w.rotation = radians or 0
	if not col then return end
	col.T = col.T or {}
	col.VT = col.VT or {}
	col.T.r = w.rotation
	col.VT.r = w.rotation
end

function M.set_label_text(label, text)
	local w = widget()
	w.label_text = text or state.LABEL_END_RUN
	if not label or not label.config then return end
	label.config.text = w.label_text
	label.config.text_drawable = nil
	label.config.prev_value = nil
	label.config.scale = M.label_scale_for(w.label_text)
	if label.update_text then label:update_text() end
	if label.panel and label.panel.recalculate then
		label.panel:recalculate()
	end
end

function M.set_display_mode(col, mode, opts)
	opts = opts or {}
	local w = widget()
	local label = M.label_node(col)
	if mode == "next" then
		w.mode = "next"
		w.panel_colour = opts.panel_colour or (game() and game().C and game().C.BLUE) or M.blue_colour()
		w.button_action = "classic_stage_next"
		M.set_label_text(label, opts.label_text or state.LABEL_NEXT)
		if label and label.config then
			label.config.colour = opts.label_colour or M.label_colour()
		end
	else
		w.mode = "end_run"
		w.panel_colour = opts.panel_colour or M.red_colour()
		w.button_action = "end_run_from_sidebar"
		M.set_label_text(label, opts.label_text or state.LABEL_END_RUN)
		if label and label.config then
			label.config.colour = opts.label_colour or M.label_colour()
		end
	end
	if col and col.config then
		col.config.colour = w.panel_colour
		col.config.button = w.button_action
	end
end

function M.apply_widget_to_proxy()
	local w = widget()
	local col = M.button_column()
	if not col or not col.config then return end
	col.config.button = w.button_action
	col.config.colour = w.panel_colour or M.red_colour()
	col.config.visible = w.visible
	if col.states then col.states.visible = w.visible end
	col.T = col.T or {}
	col.VT = col.VT or {}
	col.T.r = w.rotation
	col.VT.r = w.rotation
	local label = M.label_node(col)
	if label and label.config then
		label.config.text = w.label_text
		label.config.scale = M.label_scale_for(w.label_text)
		if label.update_text then label:update_text() end
	end
end

function M.draw(rect)
	local w = widget()
	if not rect or not w.visible then return end
	if not love or not love.graphics then return end
	local attach = game().SIDEBAR_ATTACH and game().SIDEBAR_ATTACH.T
	local ox = (attach and attach.x) or 0
	local oy = (attach and attach.y) or 0
	local x, y, rw, rh = ox + rect.x, oy + rect.y, rect.w, rect.h
	local colour = w.panel_colour or M.red_colour()
	love.graphics.push()
	love.graphics.translate(x + rw * 0.5, y + rh * 0.5)
	love.graphics.rotate(w.rotation or 0)
	love.graphics.translate(-rw * 0.5, -rh * 0.5)
	love.graphics.setColor(colour)
	love.graphics.rectangle("fill", 0, 0, rw, rh)
	local scale = M.label_scale_for(w.label_text)
	local tw, th = M.text_box_size(w.label_text, scale)
	love.graphics.setColor(M.label_colour())
	love.graphics.print(w.label_text, (rw - tw) * 0.5, (rh - th) * 0.5, 0, scale * (game().TILESCALE or 1))
	love.graphics.pop()
end

return M
