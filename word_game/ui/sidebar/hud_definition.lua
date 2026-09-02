--[[ word_game/ui/sidebar/hud_definition.lua - Vault HUD layout ]]

local Layout = require("word_game.ui.layout")
local deck = require("word_game.model.cards.deck")
local stamp_grid = require("word_game.ui.stamp_grid")

local M = {}

local VAULT_ROOT_PAD = 0
local VAULT_OUTER_PAD = 0
local VAULT_FILL_PAD = 0.06
local VAULT_BOTTOM_PAD = 0.22

local function stamp_slot_height()
	local count = 1
	if WORD_GAME and WORD_GAME.PerkStamp and WORD_GAME.PerkStamp.stack_count then
		count = WORD_GAME.PerkStamp.stack_count()
	end
	return stamp_grid.panel_height_tiles(count)
end

local function vault_fixed_content_height()
	local _, deck_h = Layout.deck_slot_size()
	local _, discard_h = Layout.discard_slot_size()
	local rows = stamp_slot_height()
		+ deck_h
		+ 0.35
		+ discard_h
		+ VAULT_BOTTOM_PAD
	local fill_nodes = 5
	local fill_pad = VAULT_FILL_PAD * (fill_nodes + 1)
	local outer_pad = VAULT_OUTER_PAD * 2
	return VAULT_ROOT_PAD * 2 + outer_pad + fill_pad + rows
end

local function vault_spacer_height()
	return math.max(0, Layout.vault_height() - vault_fixed_content_height())
end

local function box_width()
	return Layout.sidebar_width()
end

local function deck_count_node(box_w)
	G.GAME = G.GAME or {}
	deck.sync_deck_count_display()
	return { n = G.UI.ROW, config = {
		align = "cm",
		id = "row_deck_count",
		minw = box_w,
		padding = 0,
	}, nodes = {
		{ n = G.UI.TEXT, config = {
			text = "Cards left: ",
			scale = 0.38,
			colour = G.C.UI.TEXT_LIGHT,
			shadow = true,
		}},
		{ n = G.UI.TEXT, config = {
			ref_table = G.GAME,
			ref_value = "deck_left_count",
			scale = 0.38,
			colour = G.C.UI.TEXT_LIGHT,
			shadow = true,
		}},
	}}
end

function M.sync_action_buttons()
	if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync then
		WORD_GAME.HandShuffle.sync()
	end
end

function M.hud_definition()
	local box_w = box_width()
	local vault_h = Layout.vault_height()
	local stamp_h = stamp_slot_height()

	local inner_h = math.max(4, vault_h - VAULT_ROOT_PAD * 2)
	local fill_h = math.max(3.5, inner_h - VAULT_OUTER_PAD * 2)

	local fill_nodes = {
		{ n = G.UI.ROW, config = {
			id = "row_stamp_slot",
			minh = stamp_h,
			minw = box_w,
			align = "cm",
			padding = 0,
		}, nodes = {} },
		{ n = G.UI.ROW, config = {
			id = "row_vault_spacer",
			minh = vault_spacer_height(),
		}, nodes = {} },
		(function()
			local dw, dh = Layout.deck_slot_size()
			return { n = G.UI.ROW, config = {
				align = "cm",
				id = "row_deck",
				minw = box_w,
				minh = dh,
				maxh = dh,
			}, nodes = {
				{ n = G.UI.BOX, config = { w = dw, h = dh } },
			}}
		end)(),
		deck_count_node(box_w),
		(function()
			local dw, dh = Layout.discard_slot_size()
			return { n = G.UI.ROW, config = {
				align = "cm",
				id = "row_discard",
				minw = box_w,
				minh = dh,
				maxh = dh,
			}, nodes = {
				{ n = G.UI.BOX, config = { w = dw, h = dh } },
			}}
		end)(),
		{ n = G.UI.ROW, config = {
			id = "row_vault_bottom_pad",
			minh = VAULT_BOTTOM_PAD,
		}, nodes = {} },
	}

	return { n = G.UI.ROOT, config = {
		align = "tm",
		padding = VAULT_ROOT_PAD,
		colour = G.C.UI.TRANSPARENT_DARK,
		minh = vault_h,
		minw = box_w,
	}, nodes = {
		{ n = G.UI.ROW, config = {
			align = "tm",
			padding = VAULT_OUTER_PAD,
			colour = G.C.DYN_UI.MAIN,
			r = 0.1,
			id = "row_vault_outer",
			minh = inner_h,
			minw = box_w,
		}, nodes = {
			{ n = G.UI.ROW, config = {
				align = "tm",
				colour = G.C.DYN_UI.BOSS_DARK,
				r = 0.1,
				id = "row_vault_fill",
				minh = fill_h,
				minw = box_w,
				padding = VAULT_FILL_PAD,
			}, nodes = fill_nodes },
		}},
	}}
end

function M.relayout_vault()
	if not G.VAULT_HUD then return end
	local vault_h = Layout.vault_height()
	local inner_h = math.max(4, vault_h - VAULT_ROOT_PAD * 2)
	local fill_h = math.max(3.5, inner_h - VAULT_OUTER_PAD * 2)
	local root = G.VAULT_HUD.root_node
	local outer = G.VAULT_HUD:find_node_by_id("row_vault_outer")
	local fill = G.VAULT_HUD:find_node_by_id("row_vault_fill")
	local spacer = G.VAULT_HUD:find_node_by_id("row_vault_spacer")
	local stamp_slot = G.VAULT_HUD:find_node_by_id("row_stamp_slot")
	if root and root.config then
		root.config.minh = vault_h
	end
	if outer then
		outer.config.minh = inner_h
	end
	if fill then
		fill.config.minh = fill_h
	end
	if spacer then
		spacer.config.minh = vault_spacer_height()
	end
	if stamp_slot then
		stamp_slot.config.minh = stamp_slot_height()
	end
	G.VAULT_HUD:recalculate()
	if G.VAULT_ATTACH then
		Layout.update_vault_attach()
	end
	Layout.set_screen_positions()
end

return M
