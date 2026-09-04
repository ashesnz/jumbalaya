--[[
	word_game/ui/perks/discard_bin/init.lua - Discard bin in the vault sidebar.

	2×2 sprite sheet: empty → 1 card → 2 cards → 3 cards (top-left through sheet).
	Feature gate: bin_enabled() — false until a perk enables the bin.
]]

local felt = require("word_game.ui.layout.felt")
local round_config = require("word_game.config.round_config")
local InputLock = require("word_game.model.input_lock")
local Match = require("word_game.model.match")

local M = {
	BIN_SIZE = 0.62,
	BIN_SLOT_Y_ALIGN = 0.88,
	SPRITE_COLS = 2,
}

local fill_count = 0

function M.bin_enabled()
	return false
end

function M.max_fills()
	return round_config.DISCARDS_PER_HAND
end

local function read_count()
	if G.GAME and G.GAME.discard_bin_count ~= nil then
		fill_count = G.GAME.discard_bin_count
	end
	return fill_count
end

local function write_count(count)
	fill_count = math.max(0, count or 0)
	if G.GAME then
		G.GAME.discard_bin_count = fill_count
	end
end

local function felt_boss()
	return felt.is_boss_sequence()
end

function M.uses_table_draw()
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if felt_boss() then return false end
	return true
end

function M.reset()
	write_count(0)
	M.sync_discards_left_display(true)
end

function M.fill_count()
	return read_count()
end

function M.discards_left()
	return math.max(0, M.max_fills() - read_count())
end

local function discards_left_odometer()
	if not G.VAULT_HUD or not G.VAULT_HUD.find_node_by_id then return nil end
	local node = G.VAULT_HUD:find_node_by_id("discards_left_odometer")
	return node and node.config and node.config.object
end

function M.sync_discards_left_display(force)
	local left = M.discards_left()
	G.ARGS = G.ARGS or {}
	G.ARGS.discards_left_count = left
	local odometer = discards_left_odometer()
	if not odometer then return end
	if force or not odometer.roll then
		odometer.display_count = left
	end
end

function M.roll_discards_left(from_left, to_left)
	local odometer = discards_left_odometer()
	if odometer and odometer.start_roll then
		odometer:start_roll(from_left, to_left)
	else
		M.sync_discards_left_display(true)
	end
end

function M.is_full()
	return read_count() >= M.max_fills()
end

function M.end_run_button_visible()
	if G.STAGE ~= G.STAGES.RUN then return false end
	if felt.is_boss_sequence() then return false end
	return G.STATE == G.STATES.TABLE_BOARD
end

function M.bin_sprite_visible()
	return M.bin_enabled() and M.uses_table_draw() and not M.is_full()
end

function M.should_show_end_run()
	if not M.end_run_button_visible() then return false end
	if not M.bin_enabled() then return true end
	return M.is_full()
end

function M.sync_discard_area()
	if not G.discard or not G.discard.states then return end
	local can_bin = M.bin_sprite_visible()
	G.discard.states.collide.can = can_bin
	G.discard.states.hover.can = can_bin
	G.discard.states.release_on.can = can_bin
end

function M.hide_bin_cards()
	if not G.discard or not G.discard.cards then return end
	for _, card in ipairs(G.discard.cards) do
		M.stash_bin_card(card)
	end
end

function M.stash_bin_card(card)
	if not card or card.played_pool then return end
	card.bin_stash = true
	if card.states then
		card.states.visible = false
	end
end

function M.is_pile_card_visible(card, discard_area)
	if not card or not discard_area then return false end
	if not M.uses_table_draw() or not M.bin_sprite_visible() then return false end
	if card.played_pool or card.bin_stash then return false end
	if card.states and card.states.visible == false then return false end
	return false
end

function M.sync_vault_ui()
	if not M.bin_sprite_visible() then
		M.hide_bin_cards()
	end
	M.sync_discards_left_display()
	M.sync_discard_area()
	local hud = require("word_game.ui.sidebar.hud_definition")
	if hud.sync_discard_row then
		hud.sync_discard_row()
	end
end

function M.end_run()
	if M.bin_enabled() and not M.is_full() then return false end
	if InputLock.is_table_busy() then return false end
	return Match.end_run({ won = false })
end

--- Sprite index 0–2 while the bin is active (never show the full-bin frame).
function M.sprite_frame()
	if M.bin_enabled() and not M.bin_sprite_visible() then return 0 end
	return math.min(read_count(), M.max_fills() - 1)
end

--- Row-major cell in the 2×2 sheet for `frame` (0 = top-left).
function M.sprite_cell(frame)
	frame = math.max(0, math.min(frame or 0, M.max_fills()))
	local cols = M.SPRITE_COLS
	return frame % cols, math.floor(frame / cols)
end

function M.record_discard()
	local count = read_count()
	if count >= M.max_fills() then return false end
	local from_left = M.discards_left()
	write_count(count + 1)
	M.roll_discards_left(from_left, M.discards_left())
	return true
end

function M.footprint(card_w, card_h)
	local w = card_w * M.BIN_SIZE
	local h = card_h * M.BIN_SIZE
	return w, h
end

local function bin_atlas()
	return G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.bin
end

--- Texture pixel viewport for one sheet cell (not the full atlas).
function M.sprite_viewport(frame)
	local atlas = bin_atlas()
	if not atlas or not atlas.image then
		return 0, 0, 1, 1, 1, 1
	end
	local iw, ih = atlas.image:getDimensions()
	local cols = atlas.cols or M.SPRITE_COLS
	local rows = atlas.rows or 2
	local cell_w = iw / cols
	local cell_h = ih / rows
	local col, row = M.sprite_cell(frame)
	return col * cell_w, row * cell_h, cell_w, cell_h, iw, ih
end

function M.begin_board_draw()
	G.ARGS = G.ARGS or {}
	G.ARGS.table_discard_board_draw = true
end

function M.end_board_draw()
	if G.ARGS then
		G.ARGS.table_discard_board_draw = false
	end
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
	if not M.bin_enabled() then return false end
	if not M.uses_table_draw() then return false end
	if M.is_full() then return false end
	if not card or card.REMOVED or card.area ~= G.hand then return false end
	if card.bonus_card or card.boss_temp then return false end
	if InputLock.is_table_busy() then return false end
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
	local oy = area.T.y + math.max(0, (slot_h - H) * M.BIN_SLOT_Y_ALIGN)

	local frame = M.sprite_frame()
	local qx, qy, qw, qh, iw, ih = M.sprite_viewport(frame)
	local quad = love.graphics.newQuad(qx, qy, qw, qh, iw, ih)

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
	love.graphics.draw(atlas.image, quad, ox * ts, oy * ts, 0, (W * ts) / qw, (H * ts) / qh)
	love.graphics.setColor(1, 1, 1, 1)
end

function M.draw(area)
	if not area or not M.bin_sprite_visible() then return end
	local ts = G.TILESCALE * G.TILESIZE
	draw_bin(area, ts)
end

return M
