--[[ word_game/ui/trade/quad_cache.lua - Cached cover-crop quads for marketplace backdrop ]]

local M = {}

local cache = {}

--- Returns a cached Quad + uniform scale that aspect-fills (dw, dh) from (iw, ih).
function M.cover_quad(image, dw, dh)
	if not image or not love or not love.graphics or not love.graphics.newQuad then
		return nil, 1
	end
	local iw, ih = image:getDimensions()
	local scale = math.max(dw / iw, dh / ih)
	local crop_w = math.min(iw, dw / scale)
	local crop_h = math.min(ih, dh / scale)
	local key = string.format("%d:%d:%.3f:%.3f", iw, ih, crop_w, crop_h)
	local entry = cache[key]
	if entry then
		return entry.quad, entry.scale
	end
	local qx = (iw - crop_w) * 0.5
	local qy = (ih - crop_h) * 0.5
	entry = {
		quad = love.graphics.newQuad(qx, qy, crop_w, crop_h, iw, ih),
		scale = scale,
	}
	cache[key] = entry
	return entry.quad, entry.scale
end

function M.reset()
	cache = {}
end

return M
