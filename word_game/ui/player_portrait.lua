--[[
	word_game/ui/player_portrait.lua - Circular photo above TO GO.

	Characters.png is a 5x4 sheet (19 portraits). Row 1 has 4 characters and
	an empty cell; rows 2-4 have 5. Each cell is scanned for a face, then a
	circular crop is centered on that face so the head sits inside the circle.
]]

local Layout = require("word_game.ui.layout")
local characters = { stage3_portrait_brightness = function() return 1 end }

local M = {}

local COLS, ROWS = 5, 4
local COUNT = 19
local portraits = {}
M.index = 0

-- One name per playable portrait (row-major, 4 + 5 + 5 + 5). The 5th cell
-- of row 1 on the sheet is empty.
M.NAMES = {
	[0] = "MILO",
	[1] = "ALEISHA",
	[2] = "MARCO",
	[3] = "PIP",
	[4] = "REED",
	[5] = "SAGE",
	[6] = "JULES",
	[7] = "COLE",
	[8] = "ATLAS",
	[9] = "NOVA",
	[10] = "QUINN",
	[11] = "DEX",
	[12] = "THEO",
	[13] = "ELENA",
	[14] = "MORSE",
	[15] = "VERA",
	[16] = "RORY",
	[17] = "WREN",
	[18] = "LANE",
}

local function sheet_slot(index)
	index = ((index or 0) % COUNT)
	-- Skip the blank cell after the 4 portraits on row 1.
	if index >= 4 then
		index = index + 1
	end
	return index % COLS, math.floor(index / COLS) % ROWS
end

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local font_cache = {}
local NAME_OUTLINE = { 42 / 255, 16 / 255, 96 / 255, 1 }
local NAME_MID = { 221 / 255, 68 / 255, 153 / 255, 1 }
local NAME_TOP = { 240 / 255, 192 / 255, 158 / 255, 1 }
local OUTLINE_OFFSETS = {
	{ -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 },
	{ -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 },
}

local function texture_scale()
	return (G.SETTINGS and G.SETTINGS.GRAPHICS and G.SETTINGS.GRAPHICS.texture_scaling) or 2
end

local function lum(r, g, b)
	return 0.3 * r + 0.59 * g + 0.11 * b
end

local function is_skin(r, g, b)
	r, g, b = r * 255, g * 255, b * 255
	if r < 70 then return false end
	if b > r * 0.92 and g > r * 0.85 then return false end
	if g > r + 12 then return false end
	if b > r + 8 and b > g then return false end
	if math.max(r, g, b) - math.min(r, g, b) < 22 then return false end
	return r >= g - 8 and r >= b - 8 and g >= b - 25
end

local function color_dist(r1, g1, b1, r2, g2, b2)
	return math.abs(r1 - r2) + math.abs(g1 - g2) + math.abs(b1 - b2)
end

local function sample(data, x, y)
	return data:getPixel(x, y)
end

local function find_face(data, ox, oy, cw, ch)
	local bgs = {}
	local corners = {
		{ ox + 2, oy + 2 },
		{ ox + cw - 3, oy + 2 },
		{ ox + 2, oy + ch - 3 },
		{ ox + cw - 3, oy + ch - 3 },
	}
	for i = 1, #corners do
		local r, g, b = sample(data, corners[i][1], corners[i][2])
		bgs[#bgs + 1] = { r, g, b }
	end

	local function is_bg(r, g, b)
		for i = 1, #bgs do
			local bg = bgs[i]
			if color_dist(r, g, b, bg[1], bg[2], bg[3]) < 48 / 255 then
				return true
			end
		end
		return false
	end

	local skin = {}
	for y = 0, ch - 1 do
		for x = 0, cw - 1 do
			local r, g, b = sample(data, ox + x, oy + y)
			if is_skin(r, g, b) then
				skin[#skin + 1] = { x, y }
			end
		end
	end

	local seen = {}
	local best, best_score = nil, -1
	local function key(x, y)
		return y * cw + x
	end
	local skin_set = {}
	for i = 1, #skin do
		skin_set[key(skin[i][1], skin[i][2])] = true
	end

	for i = 1, #skin do
		local sx, sy = skin[i][1], skin[i][2]
		local k0 = key(sx, sy)
		if not seen[k0] then
			local stack = { { sx, sy } }
			seen[k0] = true
			local comp = {}
			local left, right, top, bot = sx, sx, sy, sy
			local sx_sum, sy_sum = 0, 0
			while #stack > 0 do
				local p = table.remove(stack)
				comp[#comp + 1] = p
				sx_sum = sx_sum + p[1]
				sy_sum = sy_sum + p[2]
				if p[1] < left then left = p[1] end
				if p[1] > right then right = p[1] end
				if p[2] < top then top = p[2] end
				if p[2] > bot then bot = p[2] end
				local nbs = {
					{ p[1] + 1, p[2] }, { p[1] - 1, p[2] },
					{ p[1], p[2] + 1 }, { p[1], p[2] - 1 },
				}
				for n = 1, 4 do
					local nx, ny = nbs[n][1], nbs[n][2]
					if nx >= 0 and ny >= 0 and nx < cw and ny < ch then
						local kk = key(nx, ny)
						if skin_set[kk] and not seen[kk] then
							seen[kk] = true
							stack[#stack + 1] = { nx, ny }
						end
					end
				end
			end

			local area = #comp
			local bw = right - left + 1
			if area >= 250 and bw <= cw * 0.82 and area <= cw * ch * 0.22 then
				local fx = sx_sum / area
				local score = (1 - math.abs(fx / cw - 0.5) * 2) + area / 8000
				if score > best_score then
					best_score = score
					best = {
						fx = fx,
						top = top,
						bot = bot,
						left = left,
						right = right,
					}
				end
			end
		end
	end

	local fx = cw * 0.5
	local hair_top = math.floor(ch * 0.2)
	local chin = math.floor(ch * 0.85)
	if best then
		fx = best.fx
		local top = best.top
		hair_top = top
		for y = top - 1, 0, -1 do
			local dark = 0
			local x0 = math.max(0, best.left - 8)
			local x1 = math.min(cw - 1, best.right + 8)
			for x = x0, x1 do
				local r, g, b = sample(data, ox + x, oy + y)
				if not is_bg(r, g, b) and lum(r, g, b) < 110 / 255 then
					dark = dark + 1
				end
			end
			if dark >= 6 then
				hair_top = y
			elseif top - y > 10 and dark < 3 then
				break
			end
		end
		-- Don't let "hair" include the whole sky; keep it near the face.
		if top - hair_top > ch * 0.45 then
			hair_top = math.max(0, top - math.floor(ch * 0.22))
		end
		chin = math.min(best.bot, hair_top + math.floor(cw * 0.85))
	end

	local head_h = math.max(8, chin - hair_top)
	local fy = hair_top + head_h * 0.42
	return fx, fy
end

local function make_circular(index)
	index = index or 0
	local scale = texture_scale()
	local path = "resources/textures/" .. scale .. "x/Characters.png"
	local ok, data = pcall(love.image.newImageData, path)
	if not ok or not data then return nil end

	local iw, ih = data:getWidth(), data:getHeight()
	local cw = math.floor(iw / COLS + 0.5)
	local ch = math.floor(ih / ROWS + 0.5)
	local col, row = sheet_slot(index)
	local ox, oy = col * cw, row * ch

	local fx, fy = find_face(data, ox, oy, cw, ch)
	local d = math.min(cw, ch)
	local src_x = math.floor(fx - d * 0.5 + 0.5)
	local src_y = math.floor(fy - d * 0.5 + 0.5)
	src_x = math.max(0, math.min(cw - d, src_x))
	src_y = math.max(0, math.min(ch - d, src_y))

	local out = love.image.newImageData(d, d)
	local cx = (d - 1) * 0.5
	local cy = (d - 1) * 0.5
	local r2 = cx * cx
	for y = 0, d - 1 do
		for x = 0, d - 1 do
			local dx, dy = x - cx, y - cy
			if dx * dx + dy * dy <= r2 then
				local sx = src_x + x
				local sy = src_y + y
				if sx >= 0 and sy >= 0 and sx < cw and sy < ch then
					out:setPixel(x, y, data:getPixel(ox + sx, oy + sy))
				else
					out:setPixel(x, y, 0, 0, 0, 0)
				end
			else
				out:setPixel(x, y, 0, 0, 0, 0)
			end
		end
	end

	local img = love.graphics.newImage(out)
	img:setFilter("nearest", "nearest")
	return img
end

function M.image_for(index)
	index = index or 0
	if portraits[index] then return portraits[index] end
	portraits[index] = make_circular(index)
	return portraits[index]
end

local function room_translate()
	local room = G.ROOM
	if not room then return end
	local ts = G.TILESCALE * G.TILESIZE
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + room.T.x * ts,
		-room.T.h * ts * 0.5 + room.T.y * ts
	)
end

local draw_name

function M.draw_at(index, rect, show_name, name, name_rect, brightness)
	if not rect then return end
	local img = M.image_for(index)
	if not img then return end

	brightness = brightness or 1
	local ts = G.TILESCALE * G.TILESIZE
	local size = math.min(rect.w, rect.h) * ts
	local x = rect.x * ts + (rect.w * ts - size) * 0.5
	local y = rect.y * ts + (rect.h * ts - size) * 0.5
	local iw, ih = img:getWidth(), img:getHeight()

	local cr, cg, cb, ca = love.graphics.getColor()
	local prev_shader = love.graphics.getShader()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()
	love.graphics.setColor(brightness, brightness, brightness, 1)
	love.graphics.draw(img, x, y, 0, size / iw, size / ih)
	if show_name then
		draw_name(ts, name, name_rect, brightness)
	end
	love.graphics.pop()

	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)
end

function M.draw()
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.draw then
		WORD_GAME.TimelineTimer.draw()
	end
end

function M.draw_ally()
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	local alpha = G.GAME.alpha
	if not alpha or not alpha.stage3_ally_visible then return end
	local index = alpha.stage3_ally_index or 1
	M.draw_at(
		index,
		Layout.ally_portrait_rect(),
		true,
		M.NAMES[index] or "ALEISHA",
		Layout.ally_portrait_name_rect(),
		characters.stage3_portrait_brightness("ally")
	)
end

function M.draw_guest()
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	local alpha = G.GAME.alpha
	if not alpha or not alpha.stage3_guest_visible then return end
	local index = alpha.stage3_guest_index or 2
	M.draw_at(
		index,
		Layout.guest_portrait_rect(),
		true,
		M.NAMES[index] or "MARCO",
		Layout.guest_portrait_name_rect(),
		characters.stage3_portrait_brightness("guest")
	)
end

function M.name_for_index(index)
	index = (index or 0) % COUNT
	return M.NAMES[index] or "PLAYER"
end

function M.current_name()
	return M.name_for_index(M.index or 0)
end

local function name_font(px)
	px = math.max(10, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local font = love.graphics.newFont(FONT_FILE, px)
	font:setFilter("linear", "linear")
	font_cache[px] = font
	return font
end

draw_name = function(ts, name, name_rect, brightness)
	name = name or M.current_name()
	name_rect = name_rect or Layout.portrait_name_rect()
	brightness = brightness or 1
	local w = name_rect.w * ts
	local h = name_rect.h * ts
	local x = name_rect.x * ts
	local y = name_rect.y * ts
	local font_px = math.max(12, h * 0.92)
	local font = name_font(font_px)
	local text_w = font:getWidth(name)
	if text_w > w * 0.94 then
		font_px = math.max(10, math.floor(font_px * (w * 0.94) / text_w))
		font = name_font(font_px)
	end
	local layer = math.max(1, font_px / 22)
	local prev_font = love.graphics.getFont()
	love.graphics.setFont(font)
	local function name_color(c)
		return c[1] * brightness, c[2] * brightness, c[3] * brightness, c[4]
	end
	love.graphics.setColor(name_color(NAME_OUTLINE))
	for _, off in ipairs(OUTLINE_OFFSETS) do
		love.graphics.printf(name, x + off[1] * layer, y + off[2] * layer, w, "center")
	end
	love.graphics.setColor(name_color(NAME_OUTLINE))
	love.graphics.printf(name, x, y + 3 * layer, w, "center")
	love.graphics.setColor(name_color(NAME_MID))
	love.graphics.printf(name, x, y + 1.5 * layer, w, "center")
	love.graphics.setColor(name_color(NAME_TOP))
	love.graphics.printf(name, x, y, w, "center")
	if prev_font then love.graphics.setFont(prev_font) end
end

return M
