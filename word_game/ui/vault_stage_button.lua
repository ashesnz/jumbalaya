--[[
	word_game/ui/vault_stage_button.lua - End Run / Next vault button (classic stage goal).

	When the classic target is met, animates the sidebar button from red "End Run"
	to a blue panel with "Next". Pressing Next banks pending score, flies tokens,
	rolls the timeline score down to zero, then advances the hand.
]]

local RunMode = require("word_game.model.run_mode")
local InputLock = require("word_game.model.input_lock")
local table_discard = require("word_game.ui.perks.discard_bin")
local Play = require("word_game.model.jumble_play")

local M = {}

local TRANSITION_DUR = 0.55
local LABEL_END_RUN = "End Run"
local LABEL_NEXT = "Next"

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
		or (string.len(text) * 10)
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
	local Layout = require("word_game.ui.layout")
	local dw, dh = Layout.discard_slot_size()
	return label_scale_for(text, math.min(dw, dh))
end

local anim = {
	mode = "end_run",
	transitioning = false,
	transition_t = 0,
	known_next_mode = false,
}

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

local function button_column()
	if not G.VAULT_HUD or not G.VAULT_HUD.find_node_by_id then return nil end
	return G.VAULT_HUD:find_node_by_id("end_run_button")
end

local function label_node(col)
	return find_node(col, "end_run_label")
end

local function set_button_rotation(col, radians)
	if not col then return end
	col.T = col.T or {}
	col.VT = col.VT or {}
	col.T.r = radians
	col.VT.r = radians
end

local function set_label_text(label, text)
	if not label or not label.config then return end
	label.config.text = text
	label.config.text_drawable = nil
	label.config.prev_value = nil
	label.config.scale = M.label_scale_for(text)
	if label.update_text then label:update_text() end
	if label.LayoutView and label.LayoutView.recalculate then
		label.LayoutView:recalculate()
	end
end

local function set_display_mode(col, mode, opts)
	if not col or not col.config then return end
	opts = opts or {}
	local label = label_node(col)
	if mode == "next" then
		col.config.colour = opts.panel_colour or blue_colour()
		set_label_text(label, opts.label_text or LABEL_NEXT)
		if label and label.config then
			label.config.colour = opts.label_colour or label_colour()
		end
	else
		col.config.colour = opts.panel_colour or red_colour()
		set_label_text(label, opts.label_text or LABEL_END_RUN)
		if label and label.config then
			label.config.colour = opts.label_colour or label_colour()
		end
	end
end

function M.is_next_mode()
	if not table_discard.end_run_button_visible() then return false end
	if not RunMode.is_classic() then return false end
	local tt = WORD_GAME and WORD_GAME.TimelineTimer
	if not tt or not tt.is_progress_mode or not tt.is_progress_mode() then return false end
	if tt.sync_progress then tt.sync_progress() end
	return tt.goal_reached == true
end

function M.reset()
	anim.mode = "end_run"
	anim.transitioning = false
	anim.transition_t = 0
	anim.known_next_mode = false
	local col = button_column()
	if col and col.config then
		col.config.button = "end_run_from_discard_bin"
		set_display_mode(col, "end_run")
		set_button_rotation(col, 0)
	end
end

function M.sync()
	local col = button_column()
	if not col or not col.config then return end

	local show = table_discard.end_run_button_visible()
	if col.states then
		col.states.visible = show
	end
	col.config.visible = show
	if not show then return end

	if anim.mode == "next" and not anim.transitioning then
		col.config.button = "classic_stage_next"
		set_display_mode(col, "next")
		set_button_rotation(col, 0)
	elseif not anim.transitioning then
		col.config.button = "end_run_from_discard_bin"
		set_display_mode(col, "end_run")
		set_button_rotation(col, 0)
	end
end

function M.update(dt)
	dt = dt or 0
	if not table_discard.end_run_button_visible() then
		if anim.mode ~= "end_run" or anim.transitioning then
			M.reset()
		end
		return
	end

	local next_mode = M.is_next_mode()
	local col = button_column()

	if next_mode ~= anim.known_next_mode then
		anim.known_next_mode = next_mode
		if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync_visibility then
			WORD_GAME.HandShuffle.sync_visibility()
		end
	end

	if next_mode and anim.mode == "end_run" and not anim.transitioning then
		anim.transitioning = true
		anim.transition_t = 0
	elseif not next_mode and (anim.mode == "next" or anim.transitioning) then
		M.reset()
		M.sync()
		return
	end

	if anim.transitioning and col then
		anim.transition_t = anim.transition_t + dt
		local u = ease_out_cubic(anim.transition_t / TRANSITION_DUR)
		set_button_rotation(col, u * math.pi * 2)

		if u < 0.42 then
			col.config.button = "end_run_from_discard_bin"
			set_display_mode(col, "end_run", { panel_colour = red_colour() })
		else
			local morph = (u - 0.42) / 0.58
			col.config.button = "classic_stage_next"
			set_display_mode(col, "next", {
				panel_colour = lerp_colour(red_colour(), blue_colour(), morph),
				label_text = LABEL_NEXT,
			})
		end

		if anim.transition_t >= TRANSITION_DUR then
			anim.transitioning = false
			anim.mode = "next"
			col.config.button = "classic_stage_next"
			set_display_mode(col, "next")
			set_button_rotation(col, 0)
		end
	elseif anim.mode == "next" and col then
		col.config.button = "classic_stage_next"
		set_display_mode(col, "next")
	end
end

local function commit_pending_score()
	local wr = G.GAME and G.GAME.word_round
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
	if not M.is_next_mode() and anim.mode ~= "next" then return false end
	if InputLock.is_table_busy() then return false end
	local token_reward = WORD_GAME and WORD_GAME.TokenReward
	if token_reward and token_reward.is_active and token_reward.is_active() then
		return false
	end

	local amount = commit_pending_score()
	if amount <= 0 then return false end

	if Play.on_hand_cleared then
		Play.on_hand_cleared()
	end
	return true
end

function M.press()
	if M.is_next_mode() or anim.mode == "next" then
		return M.collect_and_advance()
	end
	return table_discard.end_run()
end

return M
