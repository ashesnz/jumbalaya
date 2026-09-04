--[[ word_game/config/perks.lua - Perk pool for stamp rewards

	Perks are collected on the vault sidebar for display. Gameplay effects are
	not wired yet — has_perk() is reserved for future scoring hooks.
]]

local dimensions = require("word_game.config.dimensions")

local M = {}

M.RANDOM_SEED_PREFIX = "perk_pick_"
M.SLOT_COUNT = 12

-- Vault stamp imprint window: width as a fraction of the sidebar panel.
-- Design reference width is 190 px at the canonical 3.0-tile vault (73 px/tile).
local ref_vault_w_px = dimensions.layout.TABLE_BOARD_SIDEBAR_WIDTH * dimensions.CANVAS_TILE_PX
M.STAMP_SLOT_WIDTH_FRAC = 190 / ref_vault_w_px
M.STAMP_SLOT_ASPECT = 90 / 190

-- Perks.png: 3×2 grid of horizontal voucher tickets (measured pixel bounds).
-- Regions are authored against the native 908×275 sheet. Runtime atlases may
-- report a different logical size (1x downsample, or 2x loaded with dpiscale=2).
M.SHEET_W = 908
M.SHEET_H = 275
M.STAMP_COLS = 3
M.STAMP_ROWS = 2
M.STAMP_REGIONS = {
	{
		{ x = 8, y = 12, w = 287, h = 125 },
		{ x = 308, y = 12, w = 295, h = 124 },
		{ x = 617, y = 12, w = 286, h = 125 },
	},
	{
		{ x = 8, y = 147, w = 287, h = 125 },
		{ x = 308, y = 147, w = 294, h = 125 },
		{ x = 616, y = 147, w = 287, h = 125 },
	},
}

M.STAMP_SPRITES = {
	{ id = "stamp_1", pos = { x = 0, y = 0 } },
	{ id = "stamp_2", pos = { x = 1, y = 0 } },
	{ id = "stamp_3", pos = { x = 2, y = 0 } },
	{ id = "stamp_4", pos = { x = 0, y = 1 } },
	{ id = "stamp_5", pos = { x = 1, y = 1 } },
	{ id = "stamp_6", pos = { x = 2, y = 1 } },
}

local stamp_aspect = 0
for row = 1, M.STAMP_ROWS do
	for col = 1, M.STAMP_COLS do
		local region = M.STAMP_REGIONS[row][col]
		stamp_aspect = stamp_aspect + region.w / region.h
	end
end
M.STAMP_ASPECT = stamp_aspect / (M.STAMP_COLS * M.STAMP_ROWS)

-- Marketplace vouchers use the same sheet regions.
M.VOUCHER_COLS = M.STAMP_COLS
M.VOUCHER_ROWS = M.STAMP_ROWS
M.VOUCHER_REGIONS = M.STAMP_REGIONS

local voucher_aspect = 0
local voucher_count = 0
for row = 1, M.VOUCHER_ROWS do
	for col = 1, M.VOUCHER_COLS do
		local region = M.VOUCHER_REGIONS[row][col]
		voucher_aspect = voucher_aspect + region.w / region.h
		voucher_count = voucher_count + 1
	end
end
M.VOUCHER_ASPECT = voucher_aspect / voucher_count

function M.stamp_sprite_at(col, row)
	col = col + 1
	row = row + 1
	return M.STAMP_SPRITES[(row - 1) * M.STAMP_COLS + col]
end

M.DESCRIPTION_VARIABLES = {}

-- Sprites from resources/assets/Perks.png (3×2 horizontal voucher grid).
M.POOL = {
    {
        id = "wide_hand",
        name = "Wide Hand",
        desc = "Your hand size is increased to 8 cards.",
        token_cost = 10,
        pos = { x = 0, y = 0 },
    },
	{
        id = "combo_starter",
        name = "Hot Start",
        desc = "Each puzzle starts with a 1.2× multiplier.",
        token_cost = 10,
        pos = { x = 4, y = 0 },
    },
    {
        id = "combo_master",
        name = "Combo Master",
        desc = "Each additional word increases the multiplier by +0.3× instead of +0.2×.",
        token_cost = 10,
        pos = { x = 5, y = 0 },
    },
    {
        id = "combo_keeper",
        name = "Combo Keeper",
        desc = "Banking a puzzle preserves 0.2× of your current multiplier for the next puzzle.",
        token_cost = 10,
        pos = { x = 6, y = 0 },
    },
	{
		id = "letter_boost",
		name = "Letter Boost",
		desc = "High-tier letters score +2 bonus points. (Cosmetic — effect not active yet.)",
		token_cost = 10,
		pos = { x = 2, y = 0 },
	},
	{
		id = "red_rush",
		name = "Red Rush",
		desc = "Red letters score +1 bonus point. (Cosmetic — effect not active yet.)",
		token_cost = 10,
		pos = { x = 3, y = 0 },
	},
	{
		id = "vowel_veil",
		name = "Vowel Veil",
		desc = "Vowels score +2 bonus points. (Cosmetic — effect not active yet.)",
		token_cost = 10,
		pos = { x = 4, y = 0 },
	},
	{
		id = "long_word",
		name = "Long Word",
		desc = "Words of 6+ letters gain +15 bonus points. (Cosmetic — effect not active yet.)",
		token_cost = 10,
		pos = { x = 5, y = 0 },
	},
	{
		id = "extra_redraw",
		name = "Extra Redraw",
		desc = "+1 redraw this showdown.",
		token_cost = 10,
		pos = { x = 6, y = 0 },
	},
	{
		id = "time_bank",
		name = "Time Bank",
		desc = "Banking a solved puzzle restores 2 seconds. But lose 2 seconds for next word",
		token_cost = 10,
		pos = { x = 0, y = 1 },
	},
	{
		id = "speed_demon",
		name = "Speed Demon",
		desc = "Words played within 3 seconds gain +0.2× multiplier.",
		token_cost = 10,
		pos = { x = 1, y = 1 },
	},
	{
		id = "time_saver",
		name = "Time Saver",
		desc = "Every 5 seconds remaining when a stage is cleared grants +5 bonus points.",
		token_cost = 10,
		pos = { x = 2, y = 1 },
	},
	{
		id = "last_second",
		name = "Last Second",
		desc = "Words played with less than 10 seconds remaining gain +50% points.",
		token_cost = 10,
		pos = { x = 3, y = 1 },
	},
	{
    	id = "risky_business",
    	name = "Risky Business",
    	desc = "Words of 6+ letters gain +0.5× multiplier, but words of 3 letters gain -0.2×.",
		token_cost = 10,
    	pos = { x = 0, y = 2 },
    },
    {
    	id = "greedy",
    	name = "Greedy",
    	desc = "If you play 3 or more words on a puzzle, gain +20% points when banking it.",
		token_cost = 10,
    	pos = { x = 1, y = 2 },
    },
}


function M.by_id(id)
	for _, perk in ipairs(M.POOL) do
		if perk.id == id then return perk end
	end
	return nil
end

return M
