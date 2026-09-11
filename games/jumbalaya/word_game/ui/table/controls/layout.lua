--[[ word_game/ui/table/controls/layout.lua - Hand shuffle/play button positioning ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local felt_layout = require("word_game.ui.layout.felt")
local facade = require("word_game.ui.facade")
local definition = require("word_game.ui.table.controls.definition")
local TableControlsView = require("word_game.ui.views.table_controls_view")

local M = {}

local animate_mod

function M.bind_animate(mod)
	animate_mod = mod
end

local function animate()
	return animate_mod
end

local HAND_BOTTOM_MARGIN = 0.25
local pos_sig = nil
local locked_anchors = nil
local SNAP_EPS = 0.004

function M.invalidate_layout()
	pos_sig = nil
	locked_anchors = nil
end

function M.layout_pos_sig()
	local felt = felt_layout.hand_felt_rect()
	return string.format(
		"%.4f|%.4f|%.4f|%.4f|%.4f|%d",
		runtime().TILE_W or 0,
		runtime().TILE_H or 0,
		runtime().CARD_H or 0,
		felt.x,
		felt.w,
		facade.hand_size().get()
	)
end

function M.button_anchors()
	if locked_anchors and locked_anchors.sig == pos_sig then
		return locked_anchors
	end
	local size = definition.button_size()
	local gap = definition.play_gap()
	local hand_size = facade.hand_size().get()
	local hand_w = get_hand_area_width(hand_size)
	local hand_h = (runtime().CARD_H or 1.4) * 0.95
	local felt = felt_layout.hand_felt_rect()
	local hand_x = felt.x + math.max(0, (felt.w - hand_w) * 0.5)
	local hand_y = runtime().TILE_H - hand_h - HAND_BOTTOM_MARGIN
	local center_y = hand_y + hand_h * 0.5
	locked_anchors = {
		sig = pos_sig,
		size = size,
		shuffle_x = hand_x - gap - size,
		play_x = hand_x + hand_w + gap,
		y = center_y - size * 0.5,
	}
	return locked_anchors
end

local function room_center_offset(x, y, size)
	return {
		x = x + size * 0.5 - (runtime().TILE_W or 20) * 0.5,
		y = y + size * 0.5 - (runtime().TILE_H or 11.5) * 0.5,
	}
end

local function dragging_hand_card()
	local target = runtime().INPUT and runtime().INPUT.dragging and runtime().INPUT.dragging.target
	return target and target.states and target.states.drag and target.states.drag.is
		and target.area == runtime().dealt_letters
end

function M.hand_position_drift()
	if not runtime().dealt_letters then return false end
	if math.abs((runtime().dealt_letters.VT.x or 0) - (runtime().dealt_letters.T.x or 0)) > SNAP_EPS then return true end
	if math.abs((runtime().dealt_letters.VT.y or 0) - (runtime().dealt_letters.T.y or 0)) > SNAP_EPS then return true end
	for _, card in ipairs(runtime().dealt_letters.cards or {}) do
		if card.states and card.states.drag and card.states.drag.is then
			goto continue
		end
		local vt, t = card.VT, card.T
		if card.placement_recall_slide then
			goto continue
		end
		if vt and t and (math.abs(vt.x - t.x) > SNAP_EPS or math.abs(vt.y - t.y) > SNAP_EPS) then
			return true
		end
		::continue::
	end
	return false
end

function M.snap_bar(bar)
	if not bar then return end
	animate().clear_bounce(bar)
	if bar.root_node then
		animate().clear_bounce(bar.root_node)
	end
	if bar.snap_VT then
		bar:snap_VT()
	end
	if bar.root_node and bar.root_node.snap_VT then
		bar.root_node:snap_VT()
	end
	bar.STATIONARY = true
end

function M.snap_hand_container()
	if not runtime().dealt_letters or dragging_hand_card() then return end
	runtime().dealt_letters:snap_VT()
	if runtime().dealt_letters.velocity then
		runtime().dealt_letters.velocity.x = 0
		runtime().dealt_letters.velocity.y = 0
		runtime().dealt_letters.velocity.r = 0
		runtime().dealt_letters.velocity.scale = 0
	end
end

function M.snap_hand_cards()
	if not runtime().dealt_letters or dragging_hand_card() then return end
	for _, card in ipairs(runtime().dealt_letters.cards or {}) do
		if card.states and card.states.drag and card.states.drag.is then
			goto continue
		end
		if card.bounce or card.shuffle_hop or card.placement_recall_slide then
			goto continue
		end
		if card.hard_set_T then
			card:hard_set_T()
		end
		::continue::
	end
end

local function refresh_bar_tree(bar)
	if not bar or not bar.root_node then return end
	bar.root_node:move_with_major(0)
	bar.root_node:initialize_VT()
end

function M.place_bar(bar, x, y, size)
	if not bar then return end
	local offset = room_center_offset(x, y, size)
	bar.config.major = runtime().ROOM_ATTACH
	bar.config.align = "cm"
	bar.config.offset = offset
	if bar.set_alignment then
		bar:set_alignment({
			major = runtime().ROOM_ATTACH,
			type = "cm",
			offset = offset,
		})
	end
	bar.T.w = size
	bar.T.h = size
	if bar.align_to_major then
		bar:align_to_major()
	end
	if bar.hard_set_T then
		bar:hard_set_T(bar.T.x, bar.T.y, size, size)
	end
	refresh_bar_tree(bar)
	M.snap_bar(bar)
end

function M.place_action_bars()
	if not runtime().ROOM_ATTACH then return end
	local sig = M.layout_pos_sig()
	if locked_anchors and locked_anchors.sig ~= sig then
		locked_anchors = nil
	end
	pos_sig = sig
	local anchors = M.button_anchors()
	local size = anchors.size
	if runtime().table_shuffle_bar and not runtime().table_shuffle_bar.REMOVED then
		M.place_bar(runtime().table_shuffle_bar, anchors.shuffle_x, anchors.y, size)
	end
	if runtime().hand_action_bar and not runtime().hand_action_bar.REMOVED then
		M.place_bar(runtime().hand_action_bar, anchors.play_x, anchors.y, size)
	end
end

function M.sync_position()
	if not runtime().dealt_letters or not runtime().ROOM_ATTACH then return end
	local sig = M.layout_pos_sig()
	if sig == pos_sig and locked_anchors then return end
	locked_anchors = nil
	M.place_action_bars()
end

function M.snap()
	if not runtime().dealt_letters then return end
	if (not runtime().hand_action_bar or runtime().hand_action_bar.REMOVED)
		and (not runtime().table_shuffle_bar or runtime().table_shuffle_bar.REMOVED) then
		return
	end
	M.sync_position()
end

function M.ensure(visible, sync_visibility)
	if not visible() then
		M.destroy()
		return
	end
	local has_play = runtime().hand_action_bar
		and not runtime().hand_action_bar.REMOVED
		and runtime().hand_action_bar:find_node_by_id("hand_play_button")
	local has_shuffle = runtime().table_shuffle_bar
		and not runtime().table_shuffle_bar.REMOVED
		and runtime().table_shuffle_bar:find_node_by_id("hand_shuffle_button")
	if has_play and has_shuffle then
		sync_visibility()
		return
	end
	if runtime().hand_action_bar or runtime().table_shuffle_bar then
		M.destroy()
	end

	local size = definition.button_size()
	pos_sig = nil
	locked_anchors = nil
	runtime().table_shuffle_bar = TableControlsView.create_shuffle_bar(size)
	runtime().hand_action_bar = TableControlsView.create_play_bar(size)

	runtime().table_shuffle_button = runtime().table_shuffle_bar
	runtime().hand_play_button = runtime().hand_action_bar
	runtime().PLAY_WORD_UI = runtime().hand_action_bar

	M.sync_position()
	sync_visibility()
end

function M.destroy()
	pos_sig = nil
	locked_anchors = nil
	if runtime().table_shuffle_bar then
		runtime().table_shuffle_bar:remove()
		runtime().table_shuffle_bar = nil
	end
	if runtime().hand_action_bar then
		runtime().hand_action_bar:remove()
		runtime().hand_action_bar = nil
	end
	runtime().table_shuffle_button = nil
	runtime().hand_play_button = nil
	if runtime().PLAY_WORD_UI then
		runtime().PLAY_WORD_UI = nil
	end
end

return M
