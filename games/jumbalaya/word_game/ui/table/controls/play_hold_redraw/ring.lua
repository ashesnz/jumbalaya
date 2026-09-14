--[[ word_game/ui/table/controls/play_hold_redraw/ring.lua - Hold progress ring draw pass ]]

local GameRT = require("word_game.ui.util.game_runtime")
local button = require("word_game.ui.table.controls.play_hold_redraw.button")
local state = require("word_game.ui.table.controls.play_hold_redraw.state")
local NodeTransform = require("jumbalaya-engine.graphics.node_transform")

local M = {}

local function runtime()
	return GameRT.game()
end

local function draw_arc(cx, cy, radius, start_angle, end_angle, r, g, b, a, width)
	local sweep = end_angle - start_angle
	if sweep <= 0.001 then return end

	local steps = math.max(8, math.ceil(64 * (sweep / (2 * math.pi))))
	if love.graphics.setColor then love.graphics.setColor(r, g, b, a or 1) end
	if love.graphics.setLineWidth then love.graphics.setLineWidth(width) end
	if love.graphics.setLineJoin then love.graphics.setLineJoin("bevel") end
	for i = 0, steps - 1 do
		local a0 = start_angle + sweep * (i / steps)
		local a1 = start_angle + sweep * ((i + 1) / steps)
		love.graphics.line(
			cx + math.cos(a0) * radius,
			cy + math.sin(a0) * radius,
			cx + math.cos(a1) * radius,
			cy + math.sin(a1) * radius
		)
	end
end

local function find_sprite_object(uie)
	if not uie then return nil end
	if uie.config and uie.config.object and uie.config.object.VT then
		return uie.config.object
	end
	for _, child in pairs(uie.children or {}) do
		local found = find_sprite_object(child)
		if found then return found end
	end
	return nil
end

function M.draw(enabled_fn, constants)
	if not enabled_fn() then return end
	if button.gameplay_overlays_active() then return end
	if not state.holding() or state.hold_t() <= 0 then return end

	local btn = button.play_button_uie()
	if not btn or not btn.states.visible then return end

	local hold_duration = constants.HOLD_DURATION
	local progress = hold_duration <= 0 and 0 or math.min(1, state.hold_t() / hold_duration)
	local w = (btn.VT.w or 1.25) * (runtime().TILESIZE or 20)
	local h = (btn.VT.h or 1.25) * (runtime().TILESIZE or 20)
	local cx, cy = w * 0.5, h * 0.5

	local sprite = find_sprite_object(btn)
	local sprite_w = sprite and sprite.VT and sprite.VT.w and (sprite.VT.w * (runtime().TILESIZE or 20))
	local radius = (sprite_w and sprite_w > 0 and (sprite_w * 0.5)) or (math.min(w, h) * 0.5)
	local line_w = constants.RING_WIDTH

	love.graphics.push()
	if btn.container and btn.translate_container then
		btn:translate_container()
	elseif btn.panel and btn.panel.container and btn.panel.translate_container then
		btn.panel:translate_container()
	elseif runtime().ROOM and runtime().ROOM.translate_container then
		runtime().ROOM:translate_container()
	end

	NodeTransform.push_node_transform(btn, 1)
	love.graphics.scale(1 / (runtime().TILESIZE or 1))

	local a_top = -math.pi * 0.5

	draw_arc(cx, cy, radius, a_top, a_top + 2 * math.pi, 0.45, 0.40, 0.15, 0.35, line_w)

	if progress < 1.0 then
		local a_start = a_top + progress * 2 * math.pi
		local a_end = a_top + 2 * math.pi

		draw_arc(cx, cy, radius, a_start, a_end, 1.0, 0.90, 0.20, 0.45, line_w + 2.5)
		draw_arc(cx, cy, radius, a_start, a_end, 1.0, 0.94, 0.12, 1.0, line_w)
		draw_arc(cx, cy, radius, a_start, a_end, 1.0, 1.0, 0.65, 0.75, math.max(1, line_w - 1.5))
	end

	love.graphics.pop()
	love.graphics.pop()
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1, 1, 1, 1)
end

return M
