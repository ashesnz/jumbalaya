--[[ word_game/ui/perks/stamp/render_pass.lua - Sidebar stamp draw pass ]]

local game = require("word_game.ui.util.game_runtime").game

local stamp_layout = require("word_game.ui.perks.stamp.layout")
local stamp_puff = require("word_game.ui.perks.stamp.puff")
local draw = require("word_game.ui.perks.stamp.draw")
local animate = require("word_game.ui.perks.stamp.animate")
local geometry = require("word_game.ui.perks.stamp.geometry")

local M = {}

--- Discard-bin stamp is redrawn in DiscardBin.draw_discard_foreground (above cards).
local function skip_discard_bin_imprint(entry)
	local vd = WORD_GAME_UI and WORD_GAME_UI.DiscardBin
	if not vd or not vd.resolve_discard_perk or not vd.uses_table_draw then
		return false
	end
	if not vd.resolve_discard_perk(entry) then
		return false
	end
	return vd.uses_table_draw()
end

function M.draw_pass()
	if game().STATE ~= game().STATES.TABLE_BOARD or not game().ROOM or not love.graphics then return end

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	stamp_layout.room_translate()

	local imprints = animate.get_imprints()
	local anim = animate.get_anim()
	for i, entry in ipairs(imprints) do
		local x, y, w, h = geometry.stamp_cell_rect_px(i)
		local alpha = 1
		if anim and i == #imprints and anim.impacted then
			local imprint_t = math.min(1, (anim.t - animate.STRIKE_DUR) / animate.IMPRINT_DUR)
			alpha = math.min(1, imprint_t * 2.2)
		end
		if skip_discard_bin_imprint(entry) then
			goto continue_imprint
		end
		draw.draw_type_imprint(entry.perk or entry.sprite, x, y, w, h, alpha)
		local discard_bin = WORD_GAME_UI.DiscardBin
		if discard_bin and discard_bin.draw_discard_overlay then
			discard_bin.draw_discard_overlay(entry, x, y, w, h)
		end
		::continue_imprint::
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

return M
