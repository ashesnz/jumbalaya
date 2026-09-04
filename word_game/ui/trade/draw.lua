--[[ word_game/ui/trade/draw.lua - Marketplace backdrop rendering ]]

local M = {}

--- Painted just before the overlay menu each frame while the marketplace is
--- open: dims the room, then stretches the Marketplace art edge-to-edge over
--- the modal window itself (measured live from the overlay node tree, so it
--- always matches the modal's rendered size).
function M.backdrop_pass(ctx)
	local offer = ctx.get_offer()
	if not offer or not G.OVERLAY_MENU then return end
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.marketplace_bg
	if not atlas or not atlas.image or not love.graphics or not love.graphics.draw then return end
	local room = G.ROOM and G.ROOM.T
	if not room then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local iw, ih = atlas.image:getDimensions()
	local rw = room.w * ts
	local rh = room.h * ts

	-- Modal window = outer box around the body: body OBJECT node -> contents
	-- ROW -> panel COLUMN -> outline ROW. Fall back to the whole room.
	local dx, dy, dw, dh = 0, 0, rw, rh
	local host = nil
	if G.OVERLAY_MENU.find_node_by_id then
		host = G.OVERLAY_MENU:find_node_by_id("trade_marketplace_body")
	end
	local outer = host and host.parent and host.parent.parent and host.parent.parent.parent
	local t = outer and outer.VT
	if t and t.w and t.h and t.w > 0 and t.h > 0 then
		dx, dy = t.x * ts, t.y * ts
		dw, dh = t.w * ts, t.h * ts
	end

	local prev_shader = love.graphics.getShader and love.graphics.getShader()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	ctx.room_translate()
	-- Dim the table behind the modal; the art sits on top in the modal frame.
	love.graphics.setColor(0, 0, 0, 0.45)
	love.graphics.rectangle("fill", 0, 0, rw, rh)
	love.graphics.setColor(1, 1, 1, 1)
	-- Aspect-preserving "cover" fill, cropped with a Quad (no scissor needed):
	-- uniform scale fills the whole modal boundary and the source rectangle is
	-- cropped symmetrically so nothing spills outside the modal.
	local scale = math.max(dw / iw, dh / ih)
	local crop_w = math.min(iw, dw / scale)
	local crop_h = math.min(ih, dh / scale)
	local qx = (iw - crop_w) * 0.5
	local qy = (ih - crop_h) * 0.5
	local quad = love.graphics.newQuad(qx, qy, crop_w, crop_h, iw, ih)
	love.graphics.draw(atlas.image, quad, dx, dy, 0, scale, scale)
	love.graphics.pop()
	if prev_shader and love.graphics.setShader then
		love.graphics.setShader(prev_shader)
	elseif love.graphics.setShader then
		love.graphics.setShader()
	end
	if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
end

return M
