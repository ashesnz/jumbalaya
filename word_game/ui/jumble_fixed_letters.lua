--[[ word_game/ui/jumble_fixed_letters.lua - Fixed puzzle letter tiles on the placement row ]]

local topology = require("word_game.model.jumble.slot_topology")

local M = {}

local fixed_anim = { offset_y = 0, alpha = 1 }
local font_cache = {}

local function tile_font(px)
	px = math.max(10, math.floor(px + 0.5))
	if font_cache[px] then return font_cache[px] end
	local font = love.graphics.newFont(px)
	font_cache[px] = font
	return font
end

function M.anim_state()
	return fixed_anim
end

function M.reset_anim()
	fixed_anim.offset_y = 0
	fixed_anim.alpha = 1
end

function M.set_anim(state)
	if not state then return end
	fixed_anim.offset_y = state.offset_y or 0
	fixed_anim.alpha = state.alpha or 1
end

function M.draw(session)
	local j = WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state()
	if not j or not j.slots or j.boss_puzzle_hidden then return end

	local geo = session.jumble_geometry
		or (G.placement_table and G.placement_table.jumble_geometry)
	if not geo then return end

	local area = session.area
	if not area then return end

	local card_w = session.ctx:card_w()
	local card_h = session.ctx:card_h()
	if area.cards and area.cards[1] then
		card_w = area.cards[1].T.w
		card_h = area.cards[1].T.h
	end

	local ts = session.ctx:tile_scale()
	local font_px = math.max(14, card_h * ts * 0.42)
	local font = tile_font(font_px)
	local tile_w = card_w * ts
	local tile_h = card_h * ts

	love.graphics.setFont(font)
	local active_len = j.puzzle and j.puzzle.kind == "span" and geo.span_active_len(j) or nil
	local span_centers = active_len and geo.span_centers(session, active_len) or nil
	local rigid_centers = not span_centers and geo.slot_centers(session) or nil

	local off_y = (fixed_anim.offset_y or 0) * ts
	local alpha = math.max(0, math.min(1, fixed_anim.alpha or 1))

	if alpha <= 0.001 then return end

	local label_font = tile_font(math.max(10, card_h * ts * 0.18))
	local is_boss = j.boss_word_active and j.puzzle and j.puzzle.boss_word

	local function draw_blank_underline(cx)
		if not cx then return end
		local px = cx * ts
		local row_y = geo.card_row_y(area, card_h)
		local line_y = (row_y + card_h) * ts - math.max(2, ts * 0.08)
		love.graphics.setLineWidth(math.max(1.5, ts * 0.06))
		love.graphics.setColor(0, 0, 0, 0.9 * alpha)
		love.graphics.line(px - tile_w / 2, line_y, px + tile_w / 2, line_y)
		love.graphics.setLineWidth(1)
	end

	local function draw_tile_body(position_label, char)
		love.graphics.setColor(0.12, 0.18, 0.28, 0.92 * alpha)
		love.graphics.rectangle("fill", -tile_w / 2, -tile_h / 2, tile_w, tile_h, 8, 8)
		love.graphics.setColor(1, 1, 1, 0.95 * alpha)
		local tw = font:getWidth(char)
		local th = font:getHeight()
		love.graphics.print(char, -tw / 2, -th / 2)
		if position_label then
			love.graphics.setFont(label_font)
			love.graphics.setColor(1, 1, 1, 0.9 * alpha)
			love.graphics.print(position_label, -tile_w / 2 + 3, -tile_h / 2 + 2)
			love.graphics.setFont(font)
		end
	end

	local function draw_single_card(cx, char, rotation, position_label)
		if not cx or char == "" then return end
		local px = cx * ts
		local py = (geo.card_row_y(area, card_h) + card_h * 0.5) * ts + off_y
		local rot = rotation or 0

		if math.abs(rot) < 0.001 then
			love.graphics.setColor(0.12, 0.18, 0.28, 0.92 * alpha)
			love.graphics.rectangle("fill", px - tile_w / 2, py - tile_h / 2, tile_w, tile_h, 8, 8)
			love.graphics.setColor(1, 1, 1, 0.95 * alpha)
			local tw = font:getWidth(char)
			local th = font:getHeight()
			love.graphics.print(char, px - tw / 2, py - th / 2)
			if position_label then
				love.graphics.setFont(label_font)
				love.graphics.setColor(1, 1, 1, 0.9 * alpha)
				love.graphics.print(position_label, px - tile_w / 2 + 3, py - tile_h / 2 + 2)
				love.graphics.setFont(font)
			end
			return
		end

		-- Do not push a transform for every fixed tile. The board is already
		-- drawn several levels deep and Love2D's graphics stack is finite.
		local half_w, half_h = tile_w / 2, tile_h / 2
		local cos_rot, sin_rot = math.cos(rot), math.sin(rot)
		local function point(x, y)
			return px + x * cos_rot - y * sin_rot,
				py + x * sin_rot + y * cos_rot
		end
		local x1, y1 = point(-half_w, -half_h)
		local x2, y2 = point(half_w, -half_h)
		local x3, y3 = point(half_w, half_h)
		local x4, y4 = point(-half_w, half_h)
		love.graphics.setColor(0.12, 0.18, 0.28, 0.92 * alpha)
		love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
		love.graphics.setColor(1, 1, 1, 0.95 * alpha)
		local tw = font:getWidth(char)
		local th = font:getHeight()
		love.graphics.setFont(font)
		love.graphics.print(char, px, py, rot, 1, 1, tw / 2, th / 2)
		if position_label then
			love.graphics.setFont(label_font)
			love.graphics.setColor(1, 1, 1, 0.9 * alpha)
			local lw = label_font:getWidth(position_label)
			local lh = label_font:getHeight()
			love.graphics.print(position_label, px, py, rot, 1, 1,
				lw / 2 - tile_w / 2 + 3, lh / 2 - tile_h / 2 + 2)
			love.graphics.setFont(font)
		end
	end

	local items = topology.fixed_letter_items(j, active_len)
	if is_boss and rigid_centers then
		for _, slot in ipairs(j.slots) do
			if slot.kind == "blank" and not slot.card then
				draw_blank_underline(rigid_centers[slot.index])
			end
		end
	end
	for _, item in ipairs(items) do
		local cx = span_centers and span_centers[item.pos] or (rigid_centers and rigid_centers[item.pos])
		draw_single_card(cx, item.char, item.rotation, is_boss and nil or item.position_label)
	end
	love.graphics.setColor(1, 1, 1, 1)
end

return M
