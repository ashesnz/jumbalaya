--[[
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
	word_game/ui/perks/stamp/init.lua - 3D rubber-stamp strike onto the sidebar.

	Stamps the row below Set/Hand with a sidebar-wide wooden block, then leaves a
	horizontal perk imprint on the side panel.
]]


local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local run_state = facade.run_state()
local perk_cfg = require("word_game.config.perks")
local definition = require("word_game.ui.perks.stamp.definition")
local draw = require("word_game.ui.perks.stamp.draw")
local animate = require("word_game.ui.perks.stamp.animate")
local geometry = require("word_game.ui.perks.stamp.geometry")
local render_pass = require("word_game.ui.perks.stamp.render_pass")
local widgets = require("word_game.ui.widgets")

local M = {}

local function refresh_sidebar()
	if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.refresh then
		WORD_GAME_UI.Sidebar:refresh()
	end
end

animate.init({
	stamp_target_px = geometry.stamp_target_px,
	screen_top_px = require("word_game.ui.perks.stamp.layout").screen_top_px,
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
	if not game_access.get() then return false end
	local resolved = perk_cfg.by_id(entry.id) or entry
	game_access.patch({ pending_stamp_perk = definition.copy_perk(resolved) })
	return true
end

function M.play(perk_entry, callback)
	if animate.is_active() then return false end
	if game().STATE ~= game().STATES.TABLE_BOARD then return false end
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

--- Opening-table demo: stamp the top-left discard-bin voucher on fresh runs.
function M.try_opening_demo()
	if M.is_active() then return false end
	if WORD_GAME_UI.FirstPlayTutorial and WORD_GAME_UI.FirstPlayTutorial.is_active()
		and WORD_GAME_UI.FirstPlayTutorial.is_active() then
		return false
	end
	if game().STATE ~= game().STATES.TABLE_BOARD then return false end
	if animate.imprint_count() > 0 then return false end
	local rs = run_state.get()
	if not rs or #(rs.perks or {}) > 0 then return false end
	local entry = perk_cfg.by_id("discard_bin")
	if not entry then return false end
	return M.play(entry)
end

function M.demo_play()
	if game().STATE ~= game().STATES.TABLE_BOARD then return end
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
	render_pass.draw_pass()
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
	local target_index = geometry.next_slot_index()
	animate.set_pending_target_index(target_index)
	refresh_sidebar()
	local _, land_cy, _, slot_y = geometry.stamp_target_px(target_index)
	animate.set_pending_target_index(nil)
	return target_index, land_cy, slot_y
end

function M.clear_runtime()
	animate.clear_runtime()
end

function M.reset()
	M.clear_runtime()
	if game().SIDEBAR_HUD and game().SIDEBAR_HUD.remove then
		pcall(function() game().SIDEBAR_HUD:remove() end)
	end
	game().SIDEBAR_HUD = nil
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
		local x, y, w, h = geometry.stamp_cell_rect_px(i)
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
	if game().STATE ~= game().STATES.TABLE_BOARD then return false end
	if game().OVERLAY_MENU then return false end
	local anim = animate.get_anim()
	if anim and not anim.finished then return false end
	if not animate.has_imprint() then return false end

	local c = game().INPUT
	if not c or c.clicked.handled or not c.clicked.target then return false end
	if Card and getmetatable(c.clicked.target) == Card then return false end

	if not mx or not my then
		if not love or not love.mouse or not love.mouse.getPosition then return false end
		mx, my = love.mouse.getPosition()
	end
	local idx = geometry.imprint_index_at(mx, my)
	if not idx then return false end

	M.show_perk_popup(animate.get_imprints()[idx].perk)
	if play_sfx then play_sfx("card_slide1", 0.95, 0.5) end
	return true
end

function M.imprint_index_at_screen(mx, my)
	return geometry.imprint_index_at(mx, my)
end

function M.debug_grid_layout(count)
	return geometry.debug_grid_layout(count)
end

return M
