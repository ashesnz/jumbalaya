--[[ word_game/ui/sidebar/hud_definition.lua - Sidebar HUD layout ]]

local Layout = require("word_game.ui.layout")
local deck = require("word_game.model.cards.deck")
local stamp_grid = require("word_game.ui.perks.stamp.grid")
local Components = require("word_game.ui.widgets.components")
local table_discard = require("word_game.ui.perks.discard_bin")

local M = {}

local SIDEBAR_ROOT_PAD = 0
local SIDEBAR_FILL_PAD = 0.06
local SIDEBAR_BOTTOM_PAD = 0.22
local SIDEBAR_COUNTER_SCALE = 0.38
local SIDEBAR_COUNTER_ROW_H = 0.35

local function sidebar_counter_text_config(opts)
	local cfg = {
		scale = SIDEBAR_COUNTER_SCALE,
		colour = G.C.UI.TEXT_LIGHT,
		shadow = true,
	}
	if opts.text then cfg.text = opts.text end
	if opts.id then cfg.id = opts.id end
	if opts.ref_table then cfg.ref_table = opts.ref_table end
	if opts.ref_value then cfg.ref_value = opts.ref_value end
	return cfg
end

local function sidebar_counter_row(box_w, row_id, label, value_node)
	return { n = G.UI.ROW, config = {
		align = "cm",
		id = row_id,
		minw = box_w,
		padding = 0,
	}, nodes = {
		{ n = G.UI.TEXT, config = sidebar_counter_text_config({ text = label }) },
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

local function sidebar_fixed_content_height()
	local _, deck_h = Layout.deck_slot_size()
	local _, end_run_h = Layout.end_run_slot_size()
	local rows = stamp_slot_height()
		+ deck_h
		+ SIDEBAR_COUNTER_ROW_H
		+ end_run_h
		+ SIDEBAR_BOTTOM_PAD
	local fill_nodes = 6
	local fill_pad = SIDEBAR_FILL_PAD * (fill_nodes + 1)
	return SIDEBAR_ROOT_PAD * 2 + fill_pad + rows
end

local function sidebar_spacer_height()
	return math.max(0, Layout.sidebar_height() - sidebar_fixed_content_height())
end

local function box_width()
	return Layout.sidebar_width()
end

local function deck_count_node(box_w)
	G.ARGS = G.ARGS or {}
	deck.sync_deck_count_display()
	return sidebar_counter_row(box_w, "row_deck_count", "Cards left: ", {
		n = G.UI.TEXT,
		config = sidebar_counter_text_config({
			id = "text_deck_count",
			ref_table = G.ARGS,
			ref_value = "deck_left_count",
		}),
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

function M.sync_end_run_row()
	if not G.SIDEBAR_HUD then return end
	local end_btn = G.SIDEBAR_HUD:find_node_by_id("end_run_button")
	set_node_visible(end_btn, table_discard.end_run_button_visible())
	table_discard.sync_discard_pile_area()
	if WORD_GAME and WORD_GAME.SidebarStageButton and WORD_GAME.SidebarStageButton.sync then
		WORD_GAME.SidebarStageButton.sync()
	end
	if G.SIDEBAR_HUD.recalculate then
		G.SIDEBAR_HUD:recalculate()
	end
end

function M.sync_action_buttons()
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.try_sync()
	end
end

function M.hud_definition()
	local box_w = box_width()
	local sidebar_h = Layout.sidebar_height()
	local stamp_h = stamp_slot_height()
	local inner_h = math.max(4, sidebar_h - SIDEBAR_ROOT_PAD * 2)
	local sidebar_grey = G.C.DYN_UI.MAIN

	local fill_nodes = {
		{ n = G.UI.ROW, config = {
			id = "row_stamp_slot",
			minh = stamp_h,
			minw = box_w,
			align = "cm",
			padding = 0,
		}, nodes = {} },
		{ n = G.UI.ROW, config = {
			id = "row_sidebar_spacer",
			minh = sidebar_spacer_height(),
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
			local dw, dh = Layout.end_run_slot_size()
			local btn_side = math.min(dw, dh)
			local stage_btn = require("word_game.ui.sidebar.stage_button")
			return { n = G.UI.ROW, config = {
				align = "cm",
				id = "row_end_run",
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
					button = "end_run_from_sidebar",
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
						scale = stage_btn.label_scale_for("End Run"),
						colour = G.C.UI.TEXT_LIGHT,
						shadow = true,
					}},
				}},
			}}
		end)(),
	}
	fill_nodes[#fill_nodes + 1] = { n = G.UI.ROW, config = {
		id = "row_sidebar_bottom_pad",
		minh = SIDEBAR_BOTTOM_PAD,
	}, nodes = {} }

	return { n = G.UI.ROOT, config = {
		align = "tm",
		padding = SIDEBAR_ROOT_PAD,
		colour = sidebar_grey,
		minh = sidebar_h,
		minw = box_w,
	}, nodes = {
		{ n = G.UI.ROW, config = {
			align = "tm",
			padding = SIDEBAR_FILL_PAD,
			colour = sidebar_grey,
			r = 0,
			id = "row_sidebar_fill",
			minh = inner_h,
			minw = box_w,
		}, nodes = fill_nodes },
	}}
end

function M.relayout()
	if not G.SIDEBAR_HUD then return end
	deck.sync_deck_count_display()
	local sidebar_h = Layout.sidebar_height()
	local inner_h = math.max(4, sidebar_h - SIDEBAR_ROOT_PAD * 2)
	local root = G.SIDEBAR_HUD.root_node
	local fill = G.SIDEBAR_HUD:find_node_by_id("row_sidebar_fill")
	local spacer = G.SIDEBAR_HUD:find_node_by_id("row_sidebar_spacer")
	local stamp_slot = G.SIDEBAR_HUD:find_node_by_id("row_stamp_slot")
	if root and root.config then
		root.config.minh = sidebar_h
	end
	if fill then
		fill.config.minh = inner_h
	end
	if spacer then
		spacer.config.minh = sidebar_spacer_height()
	end
	if stamp_slot then
		stamp_slot.config.minh = stamp_slot_height()
	end
	M.sync_end_run_row()
	table_discard.sync_voucher_counter(true)
	G.SIDEBAR_HUD:recalculate()
	if G.SIDEBAR_ATTACH then
		Layout.update_sidebar_attach()
	end
	Layout.set_screen_positions()
end

return M
