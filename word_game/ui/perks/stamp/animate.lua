--[[ word_game/ui/perks/stamp/animate.lua - stamp strike animation and imprint state ]]

local definition = require("word_game.ui.perks.stamp.definition")
local draw = require("word_game.ui.perks.stamp.draw")
local stamp_puff = require("word_game.ui.stamp_puff")
local state = require("word_game.model.state")
local perk_cfg = require("word_game.config.perks")
local perk_model = require("word_game.model.perk")

local M = {}

M.STRIKE_DUR = 1.05
M.HOLD_DUR = 0.18
M.RETRACT_DUR = 0.62
M.IMPRINT_DUR = 0.55
M.TOTAL_DUR = M.STRIKE_DUR + M.HOLD_DUR + M.RETRACT_DUR
M.FRAME_DT = 1 / 36
M.TOTAL_FRAMES = math.ceil(M.TOTAL_DUR / M.FRAME_DT)
M.START_SCALE_MUL = 2.4

local ctx = {}

local anim
local imprints = {}
local pending_target_index

local function clamp01(t)
	return draw.clamp01(t)
end

local function lerp(a, b, t)
	return draw.lerp(a, b, t)
end

local function ease_in_cubic(t)
	t = clamp01(t)
	return t * t * t
end

local function ease_out_quad(t)
	t = clamp01(t)
	local u = 1 - t
	return 1 - u * u
end

function M.init(context)
	ctx = context
end

function M.get_anim()
	return anim
end

function M.set_anim(value)
	anim = value
end

function M.get_imprints()
	return imprints
end

function M.get_pending_target_index()
	return pending_target_index
end

function M.set_pending_target_index(value)
	pending_target_index = value
end

function M.is_active()
	return anim ~= nil
end

function M.has_imprint()
	return #imprints > 0
end

function M.imprint_count()
	return #imprints
end

function M.current_imprint()
	local last = imprints[#imprints]
	return last and last.sprite
end

function M.current_imprint_perk()
	local last = imprints[#imprints]
	return last and last.perk
end

function M.current_imprints()
	return imprints
end

function M.next_slot_index()
	return #imprints + 1
end

function M.layout_stamp_count()
	local count = #imprints
	if pending_target_index then
		count = math.max(count, pending_target_index)
	elseif anim and not anim.impacted then
		count = count + 1
	end
	return math.max(1, count)
end

function M.stack_count()
	return M.layout_stamp_count()
end

function M.stamp_pose(t, anim_state)
	local squash_y = 1
	local phase = "strike"
	local approach

	if t < M.STRIKE_DUR then
		phase = "strike"
		approach = ease_in_cubic(t / M.STRIKE_DUR)
	elseif t < M.STRIKE_DUR + M.HOLD_DUR then
		phase = "hold"
		approach = 1
		local hold = 1 - (t - M.STRIKE_DUR) / M.HOLD_DUR
		squash_y = 1 - 0.12 * hold
	else
		phase = "retract"
		local u = ease_out_quad((t - M.STRIKE_DUR - M.HOLD_DUR) / M.RETRACT_DUR)
		approach = 1 - u
	end

	-- Contact point travels from above the screen onto the row; origin is
	-- solved so the rubber pad stays glued to that point at every frame.
	local cx = lerp(anim_state.start_cx, anim_state.land_cx, approach)
	local cy = lerp(anim_state.start_cy, anim_state.land_cy, approach)
	local yaw = lerp(draw.START_YAW, draw.LANDING_YAW, approach)
	local pitch = lerp(draw.START_PITCH, draw.LANDING_PITCH, approach)
	local roll = lerp(draw.START_ROLL, draw.LANDING_ROLL, approach)
	-- Shrink as it recedes toward the panel (near-camera → far-table).
	local scale = lerp(anim_state.start_scale, anim_state.land_scale, ease_out_quad(approach))
	local ox, oy = draw.anchor_to_contact(cx, cy, scale, yaw, pitch, squash_y, roll)
	return ox, oy, scale, yaw, pitch, roll, squash_y, phase, approach
end

function M.apply_imprint(sprite_entry, perk_entry)
	imprints[#imprints + 1] = {
		sprite = definition.copy_stamp(sprite_entry),
		perk = definition.copy_perk(perk_entry),
	}
	local perk = perk_cfg.by_id(perk_entry.id)
	if perk then
		perk_model.apply_choice(perk)
		state.add_perk(perk.id)
	end
	if ctx.refresh_sidebar then
		ctx.refresh_sidebar()
	end
	return true
end

function M.trigger_impact(frame)
	if frame.impacted then return end
	frame.impacted = true
	M.apply_imprint(frame.sprite_entry, frame.perk_entry)
	stamp_puff.spawn(frame.land_cx, frame.land_cy, frame.slot_w, frame.slot_h)
	if G.VIBRATION then
		G.VIBRATION = G.VIBRATION + 0.55
	end
	if play_sfx then
		play_sfx("stamp", 1.0, 0.9)
	end
end

function M.make_anim_state(sprite_entry, perk_entry, debug, target_index)
	target_index = target_index or M.next_slot_index()
	local _, _, slot_x, slot_y, slot_w, slot_h = ctx.stamp_target_px(target_index)
	local land_cx = slot_x + slot_w * 0.5
	local land_cy = slot_y + slot_h * 0.5
	local land_scale = draw.scale_for_slot(slot_w, draw.LANDING_YAW, draw.LANDING_PITCH, draw.LANDING_ROLL)
	local start_scale = land_scale * M.START_SCALE_MUL

	local start_cx = land_cx + slot_w * 0.16
	local start_cy = land_cy
	local top = ctx.screen_top_px()
	for _ = 1, 8 do
		local ox, oy = draw.anchor_to_contact(
			start_cx, start_cy, start_scale, draw.START_YAW, draw.START_PITCH, 1, draw.START_ROLL)
		local _, _, _, max_y = draw.stamp_bounds_px(
			ox, oy, start_scale, draw.START_YAW, draw.START_PITCH, 1, draw.START_ROLL)
		start_cy = start_cy + ((top - 28) - max_y)
	end

	return {
		sprite_entry = sprite_entry,
		perk_entry = perk_entry,
		target_index = target_index,
		t = 0,
		frame = 0,
		slot_x = slot_x,
		slot_y = slot_y,
		slot_w = slot_w,
		slot_h = slot_h,
		land_cx = land_cx,
		land_cy = land_cy,
		start_cx = start_cx,
		start_cy = start_cy,
		start_scale = start_scale,
		land_scale = land_scale,
		target_scale = land_scale,
		impacted = false,
		finished = false,
		debug = debug,
	}
end

function M.begin_stamp_anim(sprite_entry, perk_entry, debug)
	local target_index = M.next_slot_index()
	pending_target_index = target_index
	if ctx.refresh_sidebar then
		ctx.refresh_sidebar()
	end
	anim = M.make_anim_state(sprite_entry, perk_entry, debug, target_index)
	pending_target_index = nil
end

function M.begin_debug_anim(sprite_entry, perk_entry)
	M.begin_stamp_anim(sprite_entry, perk_entry, true)
end

function M.update(dt)
	dt = dt or (G and G.real_dt) or 0.016
	dt = math.min(0.05, dt)
	stamp_puff.update(dt)

	if not anim or anim.debug then
		if not anim and G.GAME and G.GAME.pending_stamp_perk and ctx.play_pending then
			ctx.play_pending()
		end
	end

	if not anim or anim.debug then return end
	anim.t = anim.t + dt

	if not anim.impacted and anim.t >= M.STRIKE_DUR then
		M.trigger_impact(anim)
	end

	if anim.t >= M.TOTAL_DUR then
		local done = anim
		anim = nil
		if done.callback then done.callback() end
		if ctx.refresh_sidebar then
			ctx.refresh_sidebar()
		end
	end
end

function M.debug_step()
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	if anim and anim.finished then
		anim = nil
	end

	if not anim then
		local perk_entry = definition.resolve_stamp_perk()
		local sprite_entry = definition.resolve_stamp_sprite()
		if not perk_entry or not sprite_entry then return end
		M.begin_debug_anim(sprite_entry, perk_entry)
		if play_sfx then
			play_sfx("whoosh2", 0.85, 0.5)
		end
		return
	end

	anim.frame = anim.frame + 1
	anim.t = math.min(M.TOTAL_DUR, anim.frame * M.FRAME_DT)

	if not anim.impacted and anim.t >= M.STRIKE_DUR then
		M.trigger_impact(anim)
	end

	if anim.frame >= M.TOTAL_FRAMES then
		anim.t = M.TOTAL_DUR
		anim.finished = true
	end

	stamp_puff.update(M.FRAME_DT)
end

function M.clear_runtime()
	anim = nil
	imprints = {}
	pending_target_index = nil
	stamp_puff.reset()
end

return M
