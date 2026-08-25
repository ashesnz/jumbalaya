--[[
	word_game/ui/card_hover.lua - Letter-card AP tooltip.

	Drawn with Outfit (linear) on a cream plate with a navy rim.
]]


local M = {}

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local font_cache = {}
local target = nil

local FILL = { 0.97, 0.95, 0.90, 1 }
local BORDER = { 0.22, 0.42, 0.52, 1 }
local TITLE = { 0.16, 0.28, 0.34, 1 }

local function title_font(px)
	px = math.max(12, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local ok, font = pcall(love.graphics.newFont, FONT_FILE, px)
	if not ok or not font then
		font = love.graphics.newFont(px)
	end
	font:setFilter("linear", "linear")
	font_cache[px] = font
	return font
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

local function is_letter_card(card)
	if not card or card.REMOVED then return false end
	local set = card.ability and card.ability.set
	return set == "Default" or set == "Enhanced"
end

local function card_ap(card)
	local letter = card.ability and card.ability.letter
	local base = (card.base and card.base.letter_index) or 0
	local bonus = 0
	if card.ability then
		bonus = (card.ability.bonus or 0) + (card.ability.perma_bonus or 0)
	end
	return base, bonus
end

function M.show(card)
	if is_letter_card(card) then
		target = card
	end
end

function M.hide(card)
	if not card or target == card then
		target = nil
	end
end

function M.draw()
	local card = target
	if not card or card.REMOVED or not G.ROOM then return end
	if card.facing and card.facing ~= "front" then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target == card then
		return
	end

	local base, bonus = card_ap(card)
	local total = base + bonus
	local line = tostring(total) .. " AP"
	if bonus > 0 then
		line = tostring(base) .. " + " .. tostring(bonus) .. " AP"
	end

	local ts = G.TILESCALE * G.TILESIZE
	local vt = card.VT or card.T
	local font_px = math.max(18, math.floor(ts * 0.42))
	local font = title_font(font_px)
	local pad_x = math.max(10, ts * 0.16)
	local pad_y = math.max(5, ts * 0.08)
	local tw = font:getWidth(line)
	local th = font:getHeight()
	local bw = tw + pad_x * 2
	local bh = th + pad_y * 2
	local radius = bh * 0.42
	local cx = (vt.x + vt.w * 0.5) * ts
	local y = vt.y * ts - bh - ts * 0.08

	local prev_font = love.graphics.getFont()
	local cr, cg, cb, ca = love.graphics.getColor()
	local prev_shader = love.graphics.getShader()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()

	love.graphics.setColor(0.18, 0.32, 0.38, 0.16)
	love.graphics.rectangle("fill", cx - bw * 0.5 + 1.5, y + 2.5, bw, bh, radius, radius)

	love.graphics.setColor(FILL[1], FILL[2], FILL[3], FILL[4])
	love.graphics.rectangle("fill", cx - bw * 0.5, y, bw, bh, radius, radius)

	love.graphics.setLineWidth(math.max(1.5, bh * 0.07))
	love.graphics.setLineStyle("smooth")
	love.graphics.setColor(BORDER[1], BORDER[2], BORDER[3], BORDER[4])
	love.graphics.rectangle("line", cx - bw * 0.5, y, bw, bh, radius, radius)

	love.graphics.setFont(font)
	love.graphics.setColor(TITLE[1], TITLE[2], TITLE[3], TITLE[4])
	love.graphics.print(line, cx - tw * 0.5, y + (bh - th) * 0.5)

	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	if prev_font then love.graphics.setFont(prev_font) end
	love.graphics.setColor(cr, cg, cb, ca)
end

return M
