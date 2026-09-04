--[[ word_game/ui/perks/stamp/layout.lua - stamp panel geometry and coordinate helpers ]]

local Layout = require("word_game.ui.layout")

local M = {}

function M.tile_scale()
	return (G.TILESCALE or 1) * (G.TILESIZE or 1)
end

function M.room_translate()
	local room = G and G.ROOM
	if not room or not love or not love.graphics then return end
	local ts = M.tile_scale()
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

function M.node_world_xywh(node)
	if not node then return nil end
	local role = node.role
	local major = role and role.major
	local t = node.T or node.VT
	if not t then return nil end
	if major and major.T and role.offset then
		return (major.T.x or 0) + (role.offset.x or 0),
			(major.T.y or 0) + (role.offset.y or 0),
			t.w or 0,
			t.h or 0
	end
	return t.x or 0, t.y or 0, t.w or 0, t.h or 0
end

function M.node_rect_px(node)
	local x, y, w, h = M.node_world_xywh(node)
	if not x then return nil end
	local ts = M.tile_scale()
	return x * ts, y * ts, w * ts, h * ts
end

function M.vault_width_px()
	return Layout.sidebar_width() * M.tile_scale()
end

function M.mouse_to_stamp_space(mx, my)
	local room = G and G.ROOM and G.ROOM.T
	if not room then return mx, my end
	local ts = M.tile_scale()
	local cx = room.w * ts * 0.5
	local cy = room.h * ts * 0.5
	local ox = -cx + (room.x or 0) * ts
	local oy = -cy + (room.y or 0) * ts
	local r = room.r or 0
	local x = mx - cx
	local y = my - cy
	if r ~= 0 then
		local cr, sr = math.cos(-r), math.sin(-r)
		x, y = x * cr - y * sr, x * sr + y * cr
	end
	return x - ox, y - oy
end

function M.screen_top_px()
	local room = G.ROOM and G.ROOM.T
	return ((room and room.y) or 0) * M.tile_scale() + 10
end

return M
