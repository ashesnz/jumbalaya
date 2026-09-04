--[[
	word_game/ui/perks/stamp/init.lua - 3D rubber-stamp strike onto the vault.

	Stamps the row below Set/Hand with a vault-wide wooden block, then leaves a
	horizontal perk imprint on the side panel.
]]

local Layout = require("word_game.ui.layout")
local stamp_layout = require("word_game.ui.perks.stamp.layout")
local perk_cfg = require("word_game.config.perks")
local stamp_grid = require("word_game.ui.stamp_grid")
local stamp_puff = require("word_game.ui.stamp_puff")
local widgets = require("word_game.ui.widgets")
local definition = require("word_game.ui.perks.stamp.definition")
local draw = require("word_game.ui.perks.stamp.draw")
local animate = require("word_game.ui.perks.stamp.animate")

local M = {}

local room_translate = stamp_layout.room_translate
local tile_scale = stamp_layout.tile_scale
local node_rect_px = stamp_layout.node_rect_px
local vault_width_px = stamp_layout.vault_width_px
local mouse_to_stamp_space = stamp_layout.mouse_to_stamp_space
local screen_top_px = stamp_layout.screen_top_px

local function refresh_sidebar()
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.refresh then
		WORD_GAME.Sidebar:refresh()
	end
end

local function layout_stamp_count()
	return animate.layout_stamp_count()
end

local function next_slot_index()
	return animate.next_slot_index()
end

local function stamp_panel_height_px()
	return stamp_grid.panel_height_px(nil, layout_stamp_count())
end

local function stamp_panel_rect_px(layout_count)
	layout_count = layout_count or layout_stamp_count()
	local row = G.VAULT_HUD and G.VAULT_HUD.find_node_by_id and G.VAULT_HUD:find_node_by_id("row_stamp_slot")
	local rx, ry, rw, rh = node_rect_px(row)
	if not rx then
		local vault = Layout.vault_rect()
		local ts = tile_scale()
		rx = vault.x * ts
		ry = (vault.y + 0.82) * ts
		rw = vault.w * ts
		rh = stamp_grid.panel_height_px(nil, layout_count)
	end
	local w = vault_width_px()
	local h = stamp_grid.panel_height_px(nil, layout_count)
	local box_h = math.max(rh or h, h)
	local x = rx + (rw - w) * 0.5
	local y = ry + (box_h - h) * 0.5
	return x, y, w, h, layout_count
end

local function stamp_cell_rect_px(index)
	index = index or next_slot_index()
	local count = math.max(index, layout_stamp_count())
	local panel_x, panel_y, panel_w, panel_h = stamp_panel_rect_px(count)
	return stamp_grid.cell_rect_px(panel_x, panel_y, panel_w, panel_h, index, count)
end

local function stamp_target_px(target_index)
	target_index = target_index or next_slot_index()
	local x, y, w, h = stamp_cell_rect_px(target_index)
	return x + w * 0.5, y + h * 0.5, x, y, w, h
end

local function imprint_index_at(mx, my)
	local imprints = animate.get_imprints()
	if #imprints == 0 then return nil end
	local sx, sy = mouse_to_stamp_space(mx, my)
	for i = 1, #imprints do
		local x, y, w, h = stamp_cell_rect_px(i)
		if sx >= x and sx <= x + w and sy >= y and sy <= y + h then
			return i
		end
	end
	return nil
end

animate.init({
	stamp_target_px = stamp_target_px,
	screen_top_px = screen_top_px,
	refresh_sidebar = refresh_sidebar,
	play_pending = function()
		M.play()
	end,
})

function M.is_active()
	return animate.is_active()
end

function M.roll_stamp_sprite()
	return definition.roll_stamp_sprite()
end

function M.roll_random_stamp()
	return definition.roll_stamp_sprite()
end

function M.resolve_perk(perk_entry)
	return definition.resolve_stamp_perk(perk_entry)
end

function M.queue(entry)
	if not entry or not entry.id then return false end
	if not G.GAME then return false end
	local resolved = perk_cfg.by_id(entry.id) or entry
	G.GAME.pending_stamp_perk = definition.copy_perk(resolved)
	return true
end

function M.play(perk_entry, callback)
	if animate.is_active() then return false end
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	perk_entry = definition.resolve_stamp_perk(perk_entry)
	if not perk_entry then return false end
	local sprite_entry = definition.resolve_stamp_sprite()
	if not sprite_entry then return false end

	animate.begin_stamp_anim(sprite_entry, perk_entry, false)
	local anim = animate.get_anim()
	if not anim then return false end
	anim.callback = callback
	if play_sfx then
		play_sfx("whoosh2", 0.85, 0.5)
	end
	return true
end

function M.demo_play()
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	local anim = animate.get_anim()
	if anim and not anim.debug and anim.t < animate.TOTAL_DUR then return end

	animate.set_anim(nil)
	M.play()
end

function M.debug_step()
	animate.debug_step()
end

function M.demo()
	M.debug_step()
end

function M.update(dt)
	animate.update(dt)
end

function M.draw_pass()
	if G.STATE ~= G.STATES.TABLE_BOARD or not G.ROOM or not love.graphics then return end

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()

	local imprints = animate.get_imprints()
	local anim = animate.get_anim()
	for i, entry in ipairs(imprints) do
		local x, y, w, h = stamp_cell_rect_px(i)
		local alpha = 1
		if anim and i == #imprints and anim.impacted then
			local imprint_t = math.min(1, (anim.t - animate.STRIKE_DUR) / animate.IMPRINT_DUR)
			alpha = math.min(1, imprint_t * 2.2)
		end
		draw.draw_type_imprint(entry.perk or entry.sprite, x, y, w, h, alpha)
	end

	stamp_puff.draw()

	if anim then
		local frame = anim
		local x, y, scale, yaw, pitch, roll, squash_y, phase, approach = animate.stamp_pose(frame.t, frame)
		local stamp_alpha = 1
		if phase == "retract" then
			stamp_alpha = draw.clamp01(1 - (frame.t - animate.STRIKE_DUR - animate.HOLD_DUR) / animate.RETRACT_DUR)
		end

		if stamp_alpha > 0.02 then
			draw.draw_shadow(frame.land_cx, frame.land_cy, frame.slot_w, frame.slot_h, approach, stamp_alpha)
			draw.draw_stamp_3d(x, y, scale, yaw, pitch, squash_y, stamp_alpha, roll)
		end
	end

	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)
end

function M.debug_mesh(ox, oy, scale, yaw, pitch, squash_y, roll)
	return draw.debug_mesh(ox, oy, scale, yaw, pitch, squash_y, roll)
end

function M.debug_draw_stamp(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
	draw.debug_draw_stamp(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
end

function M.debug_draw_imprint(sprite_entry, x, y, w, h, alpha)
	draw.debug_draw_imprint(sprite_entry, x, y, w, h, alpha)
end

function M.debug_next_land_px()
	local target_index = next_slot_index()
	animate.set_pending_target_index(target_index)
	refresh_sidebar()
	local _, land_cy, _, slot_y = stamp_target_px(target_index)
	animate.set_pending_target_index(nil)
	return target_index, land_cy, slot_y
end

function M.clear_runtime()
	animate.clear_runtime()
end

function M.reset()
	M.clear_runtime()
	if G.VAULT_HUD and G.VAULT_HUD.remove then
		pcall(function() G.VAULT_HUD:remove() end)
	end
	G.VAULT_HUD = nil
end

function M.has_imprint()
	return animate.has_imprint()
end

function M.imprint_count()
	return animate.imprint_count()
end

function M.imprint_cell_rects_px()
	local rects = {}
	local count = animate.imprint_count()
	for i = 1, count do
		local x, y, w, h = stamp_cell_rect_px(i)
		rects[i] = { x = x, y = y, w = w, h = h }
	end
	return rects
end

function M.stack_count()
	return animate.stack_count()
end

function M.current_imprint()
	return animate.current_imprint()
end

function M.current_imprint_perk()
	return animate.current_imprint_perk()
end

function M.current_imprints()
	return animate.current_imprints()
end

function M.show_perk_popup(perk_entry)
	if not perk_entry or not perk_entry.id then return false end
	local entry = perk_cfg.by_id(perk_entry.id) or perk_entry
	widgets.open(definition.perk_popup_definition(definition.copy_perk(entry)))
	return true
end

function M.consume_click(mx, my)
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if G.OVERLAY_MENU then return false end
	local anim = animate.get_anim()
	if anim and not anim.finished then return false end
	if not animate.has_imprint() then return false end

	local c = G.INPUT
	if not c or c.clicked.handled or not c.clicked.target then return false end
	if Card and getmetatable(c.clicked.target) == Card then return false end

	if not mx or not my then
		if not love or not love.mouse or not love.mouse.getPosition then return false end
		mx, my = love.mouse.getPosition()
	end
	local idx = imprint_index_at(mx, my)
	if not idx then return false end

	M.show_perk_popup(animate.get_imprints()[idx].perk)
	if play_sfx then play_sfx("card_slide1", 0.95, 0.5) end
	return true
end

function M.imprint_index_at_screen(mx, my)
	return imprint_index_at(mx, my)
end

function M.debug_grid_layout(count)
	local panel_x, panel_y, panel_w = stamp_panel_rect_px()
	count = count or layout_stamp_count()
	return stamp_grid.layout(panel_x, panel_y, panel_w, count)
end

return M
