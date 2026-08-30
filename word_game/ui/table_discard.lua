--[[
	word_game/ui/table_discard.lua - Discard bin in the vault sidebar.

	Draws the animated bin sprite and accepts hand cards dragged onto the pile.
]]

local felt = require("word_game.ui.layout.felt")

local M = {
	BIN_SIZE = 0.58,
	ANIM_TIME = 0.36,
}

local anim_t = 0

local function felt_boss()
	return felt.is_boss_sequence()
end

function M.uses_table_draw()
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if felt_boss() then return false end
	return WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()
end

function M.reset()
	anim_t = 0
end

function M.play_discard_anim()
	anim_t = M.ANIM_TIME
end

function M.is_animating()
	return anim_t > 0
end

function M.update(dt)
	dt = dt or (G and G.real_dt) or 0.016
	anim_t = math.max(0, anim_t - dt)
end

function M.footprint(card_w, card_h)
	local w = card_w * M.BIN_SIZE
	local h = card_h * M.BIN_SIZE
	return w, h
end

local function bin_atlas()
	return G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.bin
end

local function discard_frame()
	if anim_t <= 0 then return 0 end
	local t = 1 - (anim_t / M.ANIM_TIME)
	return math.min(3, math.floor(t * 4))
end

function M.point_in_bin(x, y)
	if not G.discard or not G.discard.T then return false end
	local pad_x = G.CARD_W * 0.12
	local pad_y = G.CARD_H * 0.12
	return x >= G.discard.T.x - pad_x
		and x <= G.discard.T.x + G.discard.T.w + pad_x
		and y >= G.discard.T.y - pad_y
		and y <= G.discard.T.y + G.discard.T.h + pad_y
end

function M.can_discard_card(card)
	if not M.uses_table_draw() then return false end
	if not card or card.REMOVED or card.area ~= G.hand then return false end
	if card.bonus_card or card.boss_temp then return false end
	if G.GAME and (G.GAME.word_score_animating or G.GAME.hand_redraw_animating
		or G.GAME.hand_shuffle_animating or G.GAME.placement_recall_animating) then
		return false
	end
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.is_animating() then
		return false
	end
	return true
end

function M.try_discard(card)
	if not M.can_discard_card(card) then return false end
	local cx = card.T.x + card.T.w * 0.5
	local cy = card.T.y + card.T.h * 0.5
	if not M.point_in_bin(cx, cy) then return false end
	local deck = WORD_GAME and WORD_GAME.Deck
	if not deck or not deck.discard_from_hand then return false end
	return deck.discard_from_hand(card)
end

local function draw_bin(area, ts)
	local atlas = bin_atlas()
	if not atlas or not atlas.image then return end

	local W = G.CARD_W * M.BIN_SIZE
	local H = G.CARD_H * M.BIN_SIZE
	local slot_w = area.T.w or W
	local slot_h = area.T.h or H
	local ox = area.T.x + math.max(0, (slot_w - W) * 0.5)
	local oy = area.T.y + math.max(0, (slot_h - H) * 0.5)

	local frame = discard_frame()
	local cols = atlas.cols or 2
	local row = math.floor(frame / cols)
	local col = frame % cols
	local iw, ih = atlas.image:getDimensions()
	local fw, fh = atlas.px, atlas.py
	local quad = love.graphics.newQuad(col * fw, row * fh, fw, fh, iw, ih)

	local dragging = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	local highlight = dragging and M.can_discard_card(dragging) and M.point_in_bin(
		dragging.T.x + dragging.T.w * 0.5,
		dragging.T.y + dragging.T.h * 0.5
	)

	if highlight then
		love.graphics.setColor(1, 1, 0.82, 1)
	else
		love.graphics.setColor(0.92, 0.92, 0.92, 1)
	end
	love.graphics.draw(atlas.image, quad, ox * ts, oy * ts, 0, (W * ts) / fw, (H * ts) / fh)
	love.graphics.setColor(1, 1, 1, 1)
end

function M.draw(area)
	if not area then return end
	M.update()
	local ts = G.TILESCALE * G.TILESIZE
	draw_bin(area, ts)
end

return M
