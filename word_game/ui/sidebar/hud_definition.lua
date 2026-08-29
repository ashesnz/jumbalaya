--[[ word_game/ui/sidebar/hud_definition.lua - Vault HUD layout and word list rows ]]

local Layout = require("word_game.ui.layout")
local hand_progress = require("word_game.ui.sidebar.hand_progress")
local deck = require("word_game.model.cards.deck")
local stamp_grid = require("word_game.ui.stamp_grid")

local M = {}

local SCALE = 0.48
local LIST_ROW_H = 0.40

local VAULT_ROOT_PAD = 0
local VAULT_OUTER_PAD = 0
local VAULT_FILL_PAD = 0.06
local VAULT_BOTTOM_PAD = 0.22
local VAULT_FILL_CHILDREN = 7

-- Word list hidden from vault; list_nodes()/list_definition() kept for reuse elsewhere.
local SHOW_VAULT_WORD_LIST = false

local function stamp_slot_height()
	return stamp_grid.panel_height_tiles()
end

local function list_height()
	if not SHOW_VAULT_WORD_LIST then
		return 0
	end
	local history = G.GAME and G.GAME.table_word_history or {}
	return math.max(0.40, #history * LIST_ROW_H)
end

local function vault_fixed_content_height()
	local _, deck_h = Layout.deck_slot_size()
	local rows = 0.82
		+ stamp_slot_height()
		+ 0.45
		+ 0.45
		+ list_height()
		+ 0.08
		+ deck_h
		+ VAULT_BOTTOM_PAD
	local fill_pad = VAULT_FILL_PAD * (VAULT_FILL_CHILDREN + 1)
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
	if G.GAME.deck_left_count == nil then
		G.GAME.deck_left_count = deck.cards_left()
	end
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

local function list_slot(entry)
	local scale = SCALE
	local box_w = box_width()
	if not entry then
		return nil
	end
	local echo = entry.echo and entry.echo > 0 and (" e" .. entry.echo) or ""
	local score_text = tostring(entry.score or 0) .. echo
	local word_node = {
		n = G.UI.TEXT,
		config = {
			text = entry.word or "",
			scale = 0.85 * scale,
			colour = G.C.WHITE,
			shadow = false,
		},
	}
	return { n = G.UI.ROW, config = {
		align = "cm",
		padding = 0.015,
		minw = box_w * 0.90,
		minh = LIST_ROW_H,
		colour = G.C.CLEAR,
	}, nodes = {
		{ n = G.UI.COLUMN, config = { align = "cl", minw = box_w * 0.62, maxw = box_w * 0.62 }, nodes = { word_node } },
		{ n = G.UI.COLUMN, config = { align = "cr", minw = box_w * 0.28 }, nodes = {
			{ n = G.UI.ROW, config = { align = "cr" }, nodes = {
				{ n = G.UI.TEXT, config = { text = score_text, scale = 0.9 * scale, colour = G.C.UI.TEXT_LIGHT, shadow = false } },
			}},
		}},
	}}
end

function M.sync_action_buttons()
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.ensure()
	end
end

function M.list_nodes()
	local history = G.GAME and G.GAME.table_word_history or {}
	local rows = {}
	for i = 1, #history do
		local slot = list_slot(history[i])
		if slot then
			rows[#rows + 1] = slot
		end
	end
	return rows
end

function M.list_definition()
	return { n = G.UI.ROOT, config = { align = "tm", colour = G.C.CLEAR, minw = box_width() }, nodes = M.list_nodes() }
end

function M.hud_definition()
	local box_w = box_width()
	local vault_h = Layout.vault_height()
	local stamp_h = stamp_slot_height()

	local inner_h = math.max(4, vault_h - VAULT_ROOT_PAD * 2)
	local fill_h = math.max(3.5, inner_h - VAULT_OUTER_PAD * 2)

	local fill_nodes = {
		{ n = G.UI.ROW, config = {
			align = "cm",
			padding = 0,
			minw = box_w,
			id = "row_hand_progress",
		}, nodes = {
			hand_progress.odometer_node(box_w),
		}},
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
		{ n = G.UI.ROW, config = {
			id = "row_perk_stamp_play",
			minh = 0.45,
			align = "cm",
			padding = 0.04,
			minw = box_w * 0.88,
			r = 0.08,
			hover = true,
			colour = G.C.UI.BACKGROUND_INACTIVE,
			button = "perk_stamp_play",
			shadow = true,
		}, nodes = {
			{ n = G.UI.TEXT, config = {
				text = "Stamp Play",
				scale = 0.24,
				colour = G.C.UI.TEXT_LIGHT,
				shadow = true,
			}},
		}},
		{ n = G.UI.ROW, config = {
			id = "row_perk_stamp",
			minh = 0.45,
			align = "cm",
			padding = 0.04,
			minw = box_w * 0.88,
			r = 0.08,
			hover = true,
			colour = G.C.UI.BACKGROUND_INACTIVE,
			button = "perk_stamp_demo",
			shadow = true,
		}, nodes = {
			{ n = G.UI.TEXT, config = {
				text = "Stamp Frame",
				scale = 0.24,
				colour = G.C.UI.TEXT_LIGHT,
				shadow = true,
			}},
		}},
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
		{ n = G.UI.ROW, config = {
			id = "row_vault_bottom_pad",
			minh = VAULT_BOTTOM_PAD,
		}, nodes = {} },
	}

	if SHOW_VAULT_WORD_LIST then
		table.insert(fill_nodes, 3, { n = G.UI.ROW, config = {
			align = "tm",
			id = "row_embedded_list",
			minw = box_w,
			padding = 0.02,
		}, nodes = M.list_nodes() })
	end

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
