--[[ word_game/ui/sidebar/hud_definition.lua - Vault HUD layout ]]

local Layout = require("word_game.ui.layout")
local deck = require("word_game.model.cards.deck")
local stamp_grid = require("word_game.ui.perks.stamp_grid")
local Components = require("word_game.ui.widgets.components")
local table_discard = require("word_game.ui.perks.discard_bin")
local Odometer = require("word_game.ui.odometer")

local M = {}

local VAULT_ROOT_PAD = 0
local VAULT_FILL_PAD = 0.06
local VAULT_BOTTOM_PAD = 0.22
local VAULT_COUNTER_SCALE = 0.38
local VAULT_COUNTER_ROW_H = 0.35

local function vault_counter_text_config(opts)
	local cfg = {
		scale = VAULT_COUNTER_SCALE,
		colour = G.C.UI.TEXT_LIGHT,
		shadow = true,
	}
	if opts.text then cfg.text = opts.text end
	if opts.id then cfg.id = opts.id end
	if opts.ref_table then cfg.ref_table = opts.ref_table end
	if opts.ref_value then cfg.ref_value = opts.ref_value end
	return cfg
end

local function vault_counter_row(box_w, row_id, label, value_node)
	return { n = G.UI.ROW, config = {
		align = "cm",
		id = row_id,
		minw = box_w,
		padding = 0,
	}, nodes = {
		{ n = G.UI.TEXT, config = vault_counter_text_config({ text = label }) },
		value_node,
	}}
end

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
		+ VAULT_COUNTER_ROW_H
		+ discard_h
		+ VAULT_BOTTOM_PAD
	if table_discard.bin_enabled() then
		rows = rows + VAULT_COUNTER_ROW_H
	end
	local fill_nodes = 6
	local fill_pad = VAULT_FILL_PAD * (fill_nodes + 1)
	return VAULT_ROOT_PAD * 2 + fill_pad + rows
end

local function vault_spacer_height()
	return math.max(0, Layout.vault_height() - vault_fixed_content_height())
end

local function box_width()
	return Layout.sidebar_width()
end

local function deck_count_node(box_w)
	G.ARGS = G.ARGS or {}
	deck.sync_deck_count_display()
	return vault_counter_row(box_w, "row_deck_count", "Cards left: ", {
		n = G.UI.TEXT,
		config = vault_counter_text_config({
			id = "text_deck_count",
			ref_table = G.ARGS,
			ref_value = "deck_left_count",
		}),
	})
end

local function discards_left_node(box_w)
	G.ARGS = G.ARGS or {}
	table_discard.sync_discards_left_display(true)
	return vault_counter_row(box_w, "row_discards_left", "Discards left: ", {
		n = G.UI.OBJECT,
		config = {
			id = "discards_left_odometer",
			object = Odometer({
				label = "",
				text_scale = VAULT_COUNTER_SCALE,
				text_shadow = true,
				value = table_discard.discards_left(),
				value_fn = function() return table_discard.discards_left() end,
				colour = G.C.UI.TEXT_LIGHT,
			}),
		},
	})
end

local function set_node_visible(node, visible)
	if not node then return end
	if node.states then
		node.states.visible = visible
	end
	if node.config then
		node.config.visible = visible
	end
end

function M.sync_discard_row()
	if not G.VAULT_HUD then return end
	local end_btn = G.VAULT_HUD:find_node_by_id("end_run_button")
	set_node_visible(end_btn, table_discard.end_run_button_visible())
	local discards_row = G.VAULT_HUD:find_node_by_id("row_discards_left")
	if discards_row then
		set_node_visible(discards_row, table_discard.bin_enabled())
	end
	table_discard.sync_discard_area()
	if WORD_GAME and WORD_GAME.VaultStageButton and WORD_GAME.VaultStageButton.sync then
		WORD_GAME.VaultStageButton.sync()
	end
	G.VAULT_HUD:recalculate()
end

function M.sync_action_buttons()
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.try_sync()
	end
end

function M.hud_definition()
	local box_w = box_width()
	local vault_h = Layout.vault_height()
	local stamp_h = stamp_slot_height()
	local inner_h = math.max(4, vault_h - VAULT_ROOT_PAD * 2)
	local vault_grey = G.C.DYN_UI.MAIN

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
			local btn_side = math.min(dw, dh)
			local vault_btn = require("word_game.ui.vault_stage_button")
			return { n = G.UI.ROW, config = {
				align = "cm",
				id = "row_discard",
				minw = box_w,
				minh = btn_side,
				maxh = btn_side,
			}, nodes = {
				{ n = G.UI.COLUMN, config = {
					align = "cm",
					padding = 0,
					r = Components.CHROME.radius,
					hover = true,
					colour = G.C.RED,
					hover_colour = G.C.UI.BUTTON_HOVER,
					button = "end_run_from_discard_bin",
					id = "end_run_button",
					minw = btn_side,
					minh = btn_side,
					maxw = btn_side,
					maxh = btn_side,
					visible = true,
					focus_args = { nav = "wide", snap_to = true },
				}, nodes = {
					{ n = G.UI.TEXT, config = {
						id = "end_run_label",
						text = "End Run",
						scale = vault_btn.label_scale_for("End Run"),
						colour = G.C.UI.TEXT_LIGHT,
						shadow = true,
					}},
				}},
			}}
		end)(),
	}
	if table_discard.bin_enabled() then
		fill_nodes[#fill_nodes + 1] = discards_left_node(box_w)
	end
	fill_nodes[#fill_nodes + 1] = { n = G.UI.ROW, config = {
		id = "row_vault_bottom_pad",
		minh = VAULT_BOTTOM_PAD,
	}, nodes = {} }

	return { n = G.UI.ROOT, config = {
		align = "tm",
		padding = VAULT_ROOT_PAD,
		colour = vault_grey,
		minh = vault_h,
		minw = box_w,
	}, nodes = {
		{ n = G.UI.ROW, config = {
			align = "tm",
			padding = VAULT_FILL_PAD,
			colour = vault_grey,
			r = 0,
			id = "row_vault_fill",
			minh = inner_h,
			minw = box_w,
		}, nodes = fill_nodes },
	}}
end

function M.relayout_vault()
	if not G.VAULT_HUD then return end
	deck.sync_deck_count_display()
	local vault_h = Layout.vault_height()
	local inner_h = math.max(4, vault_h - VAULT_ROOT_PAD * 2)
	local root = G.VAULT_HUD.root_node
	local fill = G.VAULT_HUD:find_node_by_id("row_vault_fill")
	local spacer = G.VAULT_HUD:find_node_by_id("row_vault_spacer")
	local stamp_slot = G.VAULT_HUD:find_node_by_id("row_stamp_slot")
	if root and root.config then
		root.config.minh = vault_h
	end
	if fill then
		fill.config.minh = inner_h
	end
	if spacer then
		spacer.config.minh = vault_spacer_height()
	end
	if stamp_slot then
		stamp_slot.config.minh = stamp_slot_height()
	end
	M.sync_discard_row()
	table_discard.sync_discards_left_display(true)
	G.VAULT_HUD:recalculate()
	if G.VAULT_ATTACH then
		Layout.update_vault_attach()
	end
	Layout.set_screen_positions()
end

return M
