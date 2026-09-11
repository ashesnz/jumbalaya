--[[
	word_game/ui/sidebar/stage_button.lua - End Run / Next sidebar button (classic stage goal).
]]

local facade = require("word_game.ui.facade")
local Layout = require("word_game.ui.layout")
local table_discard = require("word_game.ui.perks.discard_bin")
local game_access = require("word_game.model.game_access")
local action_dispatch = require("bridge.action_dispatch")

local function run_mode()
	return facade.run_mode()
end

local function input_lock()
	return facade.input_lock()
end

local function play()
	return facade.jumble_play()
end

local M = {}

local TRANSITION_DUR = 0.55
local LABEL_END_RUN = "End Run"
local LABEL_NEXT = "Next"

local widget = {
	mode = "end_run",
	transitioning = false,
	transition_t = 0,
	known_next_mode = false,
	visible = true,
	panel_colour = nil,
	label_text = LABEL_END_RUN,
	button_action = "end_run_from_sidebar",
	rotation = 0,
}

local bound_button
local bound_label

local function font_metrics()
	local lang = (G and G.LANG) or {}
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
	local tile = (G.TILESIZE or 20) * (G.TILESCALE or 1)
	local text_w = (metrics.face and metrics.face.getWidth and metrics.face:getWidth(text))
		or (string.len(text or "") * 10)
	local text_h = (metrics.face and metrics.face.getHeight and metrics.face:getHeight())
		or 20
	local px_w = text_w * metrics.squish * scale * (G.TILESCALE or 1) * metrics.font_scale
	local px_h = text_h * scale * (G.TILESCALE or 1) * metrics.font_scale * metrics.height_scale
	return px_w / tile, px_h / tile
end

local function label_scale_for(text, btn_side)
	local max_w = (btn_side or 0.62) * 0.9
	local max_h = (btn_side or 0.62) * 0.9
	local scale = 0.34
	local w, h = text_box_size(text, scale)
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

local function red_colour()
	return (G and G.C and G.C.RED) or { 1, 0, 0.4, 1 }
end

local function blue_colour()
	return (G and G.C and G.C.BLUE) or { 0.2, 0.5, 1, 1 }
end

local function label_colour()
	return (G and G.C and G.C.UI and G.C.UI.TEXT_LIGHT) or { 1, 1, 1, 1 }
end

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_out_cubic(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

local function lerp_colour(a, b, t)
	return {
		a[1] + (b[1] - a[1]) * t,
		a[2] + (b[2] - a[2]) * t,
		a[3] + (b[3] - a[3]) * t,
		(a[4] or 1) + ((b[4] or 1) - (a[4] or 1)) * t,
	}
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

function M.bind_button_proxy(button, label)
	bound_button = button
	bound_label = label
	if not button then
		M.reset()
	end
end

local function button_column()
	if bound_button then return bound_button end
	if G.SIDEBAR_HUD and G.SIDEBAR_HUD.find_node_by_id then
		return G.SIDEBAR_HUD:find_node_by_id("end_run_button")
	end
	return nil
end

local function label_node(col)
	if bound_label and col == bound_button then return bound_label end
	return find_node(col, "end_run_label")
end

local function apply_widget_to_proxy()
	local col = button_column()
	if not col or not col.config then return end
	col.config.button = widget.button_action
	col.config.colour = widget.panel_colour or red_colour()
	col.config.visible = widget.visible
	if col.states then col.states.visible = widget.visible end
	col.T = col.T or {}
	col.VT = col.VT or {}
	col.T.r = widget.rotation
	col.VT.r = widget.rotation
	local label = label_node(col)
	if label and label.config then
		label.config.text = widget.label_text
		label.config.scale = M.label_scale_for(widget.label_text)
		if label.update_text then label:update_text() end
	end
end

local function set_button_rotation(col, radians)
	widget.rotation = radians or 0
	if not col then return end
	col.T = col.T or {}
	col.VT = col.VT or {}
	col.T.r = widget.rotation
	col.VT.r = widget.rotation
end

local function set_label_text(label, text)
	widget.label_text = text or LABEL_END_RUN
	if not label or not label.config then return end
	label.config.text = widget.label_text
	label.config.text_drawable = nil
	label.config.prev_value = nil
	label.config.scale = M.label_scale_for(widget.label_text)
	if label.update_text then label:update_text() end
	if label.LayoutView and label.LayoutView.recalculate then
		label.LayoutView:recalculate()
	end
end

local function set_display_mode(col, mode, opts)
	opts = opts or {}
	local label = label_node(col)
	if mode == "next" then
		widget.mode = "next"
		widget.panel_colour = opts.panel_colour or (G and G.C and G.C.BLUE) or blue_colour()
		widget.button_action = "classic_stage_next"
		set_label_text(label, opts.label_text or LABEL_NEXT)
		if label and label.config then
			label.config.colour = opts.label_colour or label_colour()
		end
	else
		widget.mode = "end_run"
		widget.panel_colour = opts.panel_colour or red_colour()
		widget.button_action = "end_run_from_sidebar"
		set_label_text(label, opts.label_text or LABEL_END_RUN)
		if label and label.config then
			label.config.colour = opts.label_colour or label_colour()
		end
	end
	if col and col.config then
		col.config.colour = widget.panel_colour
		col.config.button = widget.button_action
	end
end

function M.current_label()
	return widget.label_text
end

function M.current_action()
	return widget.button_action
end

function M.current_colour()
	return widget.panel_colour or red_colour()
end

function M.is_next_mode()
	if not table_discard.end_run_button_visible() then return false end
	if not run_mode().is_classic() then return false end
	local tt = WORD_GAME_UI.TimelineTimer
	if not tt or not tt.is_progress_mode or not tt.is_progress_mode() then return false end
	if tt.sync_progress then tt.sync_progress() end
	return tt.goal_reached == true
end

function M.reset()
	widget.mode = "end_run"
	widget.transitioning = false
	widget.transition_t = 0
	widget.known_next_mode = false
	widget.rotation = 0
	widget.visible = true
	widget.panel_colour = red_colour()
	widget.label_text = LABEL_END_RUN
	widget.button_action = "end_run_from_sidebar"
	local col = button_column()
	if col and col.config then
		set_display_mode(col, "end_run")
		set_button_rotation(col, 0)
	end
end

function M.sync()
	widget.visible = table_discard.end_run_button_visible()
	local col = button_column()
	if col and col.config then
		if col.states then col.states.visible = widget.visible end
		col.config.visible = widget.visible
	end
	if not widget.visible then return end

	if widget.mode == "next" and not widget.transitioning then
		set_display_mode(col, "next")
		set_button_rotation(col, 0)
	elseif not widget.transitioning then
		set_display_mode(col, "end_run")
		set_button_rotation(col, 0)
	end
	apply_widget_to_proxy()
end

function M.update(dt)
	dt = dt or 0
	if not table_discard.end_run_button_visible() then
		if widget.mode ~= "end_run" or widget.transitioning then
			M.reset()
		end
		return
	end

	local next_mode = M.is_next_mode()
	local col = button_column()

	if next_mode ~= widget.known_next_mode then
		widget.known_next_mode = next_mode
		if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.sync_visibility then
			WORD_GAME_UI.TableControls.sync_visibility()
		end
	end

	if next_mode and widget.mode == "end_run" and not widget.transitioning then
		widget.transitioning = true
		widget.transition_t = 0
	elseif not next_mode and (widget.mode == "next" or widget.transitioning) then
		M.reset()
		M.sync()
		return
	end

	if widget.transitioning and col then
		widget.transition_t = widget.transition_t + dt
		local u = ease_out_cubic(widget.transition_t / TRANSITION_DUR)
		set_button_rotation(col, u * math.pi * 2)

		if u < 0.42 then
			set_display_mode(col, "end_run", { panel_colour = red_colour() })
		else
			local morph = (u - 0.42) / 0.58
			set_display_mode(col, "next", {
				panel_colour = lerp_colour(red_colour(), blue_colour(), morph),
				label_text = LABEL_NEXT,
			})
		end

		if widget.transition_t >= TRANSITION_DUR then
			widget.transitioning = false
			widget.mode = "next"
			set_display_mode(col, "next")
			set_button_rotation(col, 0)
		end
	elseif widget.mode == "next" and col then
		set_display_mode(col, "next")
	end
	apply_widget_to_proxy()
end

local function pointer_tile()
	if not G or not G.POINTER or not G.POINTER.T then return nil, nil end
	return G.POINTER.T.x, G.POINTER.T.y
end

function M.point_in_button(rect, tx, ty)
	if not rect or not widget.visible then return false end
	tx, ty = tx or pointer_tile()
	if not tx or not ty then return false end
	local attach = G.SIDEBAR_ATTACH and G.SIDEBAR_ATTACH.T
	if not attach then return false end
	local x = attach.x + rect.x
	local y = attach.y + rect.y
	return tx >= x and tx <= x + rect.w and ty >= y and ty <= y + rect.h
end

function M.consume_click(mx, my, rect)
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if G.OVERLAY_MENU then return false end
	if not widget.visible then return false end
	if not M.point_in_button(rect, mx, my) then return false end
	local action = widget.button_action
	if action and G.FUNCS and G.FUNCS[action] then
		action_dispatch.dispatch_func(action)
		G.FUNCS[action]()
		return true
	end
	return M.press()
end

function M.draw(rect)
	if not rect or not widget.visible then return end
	if not love or not love.graphics then return end
	local attach = G.SIDEBAR_ATTACH and G.SIDEBAR_ATTACH.T
	local ox = (attach and attach.x) or 0
	local oy = (attach and attach.y) or 0
	local x, y, w, h = ox + rect.x, oy + rect.y, rect.w, rect.h
	local colour = widget.panel_colour or red_colour()
	love.graphics.push()
	love.graphics.translate(x + w * 0.5, y + h * 0.5)
	love.graphics.rotate(widget.rotation or 0)
	love.graphics.translate(-w * 0.5, -h * 0.5)
	love.graphics.setColor(colour)
	love.graphics.rectangle("fill", 0, 0, w, h)
	local scale = M.label_scale_for(widget.label_text)
	local tw, th = text_box_size(widget.label_text, scale)
	love.graphics.setColor(label_colour())
	love.graphics.print(widget.label_text, (w - tw) * 0.5, (h - th) * 0.5, 0, scale * (G.TILESCALE or 1))
	love.graphics.pop()
end

local function commit_pending_score()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	if not j then return 0 end
	local pending = 0
	if (j.puzzle_points or 0) > 0 then
		pending = math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1))
	end
	if pending > 0 then
		j.total_score = (j.total_score or 0) + pending
		j.puzzle_points = 0
		j.puzzle_multi = 1.0
		j.puzzle_words = {}
		j.solved = false
	end
	return j.total_score or 0
end

function M.collect_and_advance()
	if not M.is_next_mode() and widget.mode ~= "next" then return false end
	if input_lock().is_table_busy() then return false end
	local token_reward = WORD_GAME_UI.TokenReward
	if token_reward and token_reward.is_active and token_reward.is_active() then
		return false
	end

	local amount = commit_pending_score()
	if amount <= 0 then return false end

	if play().on_hand_cleared then
		play().on_hand_cleared()
	end
	return true
end

function M.press()
	if M.is_next_mode() or widget.mode == "next" then
		return M.collect_and_advance()
	end
	return table_discard.end_run()
end

return M
