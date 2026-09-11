--[[ word_game/ui/table/controls/animate.lua - Hand shuffle bounce, recall, and settle ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")
local hand_shuffle_anim = require("word_game.ui.table.controls.shuffle_anim")
local hand_placement_recall_anim = require("word_game.ui.table.controls.placement_recall_anim")

local InputLock = facade.input_lock()
local game_access = require("word_game.model.game_access")

local M = {}

local layout_mod

function M.bind_layout(mod)
	layout_mod = mod
end

local function layout()
	return layout_mod
end

function M.clear_bounce(node)
	if not node then return end
	node.bounce = nil
	if node.velocity then
		node.velocity.x = 0
		node.velocity.y = 0
		node.velocity.r = 0
		node.velocity.scale = 0
	end
	for _, child in pairs(node.children or {}) do
		M.clear_bounce(child)
	end
end

local function placement_area()
	return runtime().pattern_row and runtime().pattern_row.area
end

local function jumble_active()
	return WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()
end

local function bonus_stack_ui()
	return facade.bonus_stack_ui()
end

function M.recall_placement_cards(opts)
	opts = opts or {}
	if placement_area() and placement_area().cards then
		local p_area = placement_area()
		for i = #p_area.cards, 1, -1 do
			local card = p_area.cards[i]
			if runtime().pattern_row then
				runtime().pattern_row:on_remove_card(card)
			end
			p_area:remove_card(card)
			local stack = bonus_stack_ui()
			if stack and stack.is_bonus_card(card) then
				stack.return_card(card)
			elseif runtime().dealt_letters then
				runtime().dealt_letters:emplace(card)
			end
		end
		if p_area.hard_set_cards then
			p_area:hard_set_cards()
		end
	end
	if jumble_active() then
		local wr = game_access.word_round()
		if wr and wr.jumble and wr.jumble.slots then
			WORD_GAME.Jumble.clear_blank_cards(wr.jumble.slots)
			WORD_GAME.Jumble.sync_placement_cards(wr.jumble.slots)
		end
		if runtime().pattern_row and runtime().pattern_row.jumble_geometry then
			runtime().pattern_row.jumble_geometry.relayout(runtime().pattern_row)
		end
	end
	facade.placement_word().clear()
	if runtime().dealt_letters then
		if runtime().dealt_letters.clear_selection then runtime().dealt_letters:clear_selection() end
		if runtime().dealt_letters.set_ranks then runtime().dealt_letters:set_ranks() end
		if runtime().dealt_letters.relayout then runtime().dealt_letters:relayout() end
		if not opts.skip_hand_snap then
			if runtime().dealt_letters.hard_set_cards then runtime().dealt_letters:hard_set_cards() end
			if runtime().dealt_letters.snap_VT then runtime().dealt_letters:snap_VT() end
		end
	end
end

function M.return_placement_cards_to_hand(placement_has_cards, sync_visibility)
	if not placement_has_cards() then return end
	if InputLock.is_table_busy() then return end
	if runtime().INPUT and runtime().INPUT.dragging and runtime().INPUT.dragging.target then return end
	if hand_placement_recall_anim.animate(function()
		sync_visibility()
	end) then
		return
	end
	M.recall_placement_cards()
	sync_visibility()
	if play_sfx then
		play_sfx("card_slide1", 0.9, 0.7)
	end
end

function M.stabilize()
	if not runtime().dealt_letters or (not runtime().hand_action_bar and not runtime().table_shuffle_bar) then return end
	layout().place_action_bars()
end

function M.stabilize_table_board(visible, buttons_present, sync)
	if visible() and not buttons_present() then
		sync()
	end
	M.stabilize()
	layout().snap_hand_container()
	if game_access.get() and InputLock.is_table_busy() then return end
	local game = game_access.get()
	local settle = game and game.hand_layout_settle or 0
	if settle > 0 or layout().hand_position_drift() then
		layout().snap_hand_cards()
		if settle > 0 then
			game_access.patch({ hand_layout_settle = settle - 1 })
		end
	end
end

function M.mark_layout_settle(frames)
	game_access.patch({ hand_layout_settle = frames or 4 })
end

function M.is_animating()
	return hand_shuffle_anim.is_animating() or hand_placement_recall_anim.is_animating()
end

function M.shuffle_hand(placement_has_cards)
	if placement_has_cards() then return end
	if not runtime().dealt_letters or #runtime().dealt_letters.cards < 2 then return end
	if InputLock.is_table_busy() then return end
	if runtime().INPUT and runtime().INPUT.dragging and runtime().INPUT.dragging.target then return end
	runtime().dealt_letters:clear_selection()
	hand_shuffle_anim.animate(runtime().dealt_letters)
end

return M
