--[[ word_game/ui/hand_shuffle/animate.lua - Hand shuffle bounce, recall, and settle ]]

local bonus_model = require("word_game.model.bonus_stack")
local bonus_gutter = require("word_game.board.bonus_gutter")
local InputLock = require("word_game.model.input_lock")
local hand_shuffle_anim = require("word_game.ui.hand_shuffle_anim")
local hand_placement_recall_anim = require("word_game.ui.hand_placement_recall_anim")

local M = {}

local layout_mod

local function layout()
	if not layout_mod then
		layout_mod = require("word_game.ui.hand_shuffle.layout")
	end
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
	return G.placement_table and G.placement_table.area
end

local function jumble_active()
	return WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()
end

function M.recall_placement_cards(opts)
	opts = opts or {}
	if placement_area() and placement_area().cards then
		local p_area = placement_area()
		for i = #p_area.cards, 1, -1 do
			local card = p_area.cards[i]
			if G.placement_table then
				G.placement_table:on_remove_card(card)
			end
			p_area:remove_card(card)
			if bonus_model.is_bonus_card(card) then
				bonus_gutter.return_card(card)
			elseif G.hand then
				G.hand:emplace(card)
			end
		end
		if p_area.hard_set_cards then
			p_area:hard_set_cards()
		end
	end
	if jumble_active() then
		local wr = G.GAME and G.GAME.word_round
		if wr and wr.jumble and wr.jumble.slots then
			WORD_GAME.Jumble.clear_blank_cards(wr.jumble.slots)
			WORD_GAME.Jumble.sync_placement_cards(wr.jumble.slots)
		end
		if G.placement_table and G.placement_table.jumble_geometry then
			G.placement_table.jumble_geometry.relayout(G.placement_table)
		end
	end
	local placement_word = require("word_game.model.placement_word")
	placement_word.clear()
	if G.hand then
		if G.hand.clear_selection then G.hand:clear_selection() end
		if G.hand.set_ranks then G.hand:set_ranks() end
		if G.hand.relayout then G.hand:relayout() end
		if not opts.skip_hand_snap then
			if G.hand.hard_set_cards then G.hand:hard_set_cards() end
			if G.hand.snap_VT then G.hand:snap_VT() end
		end
	end
end

function M.return_placement_cards_to_hand(placement_has_cards, sync_visibility)
	if not placement_has_cards() then return end
	if InputLock.is_table_busy() then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target then return end
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
	if not G.hand or (not G.hand_action_bar and not G.hand_shuffle_bar) then return end
	layout().place_action_bars()
end

function M.stabilize_table_board(visible, buttons_present, sync)
	if visible() and not buttons_present() then
		sync()
	end
	M.stabilize()
	layout().snap_hand_container()
	if G.GAME and InputLock.is_table_busy() then return end
	local settle = G.GAME and G.GAME.hand_layout_settle or 0
	if settle > 0 or layout().hand_position_drift() then
		layout().snap_hand_cards()
		if settle > 0 and G.GAME then
			G.GAME.hand_layout_settle = settle - 1
		end
	end
end

function M.mark_layout_settle(frames)
	if G.GAME then
		G.GAME.hand_layout_settle = frames or 4
	end
end

function M.is_animating()
	return hand_shuffle_anim.is_animating() or hand_placement_recall_anim.is_animating()
end

function M.shuffle_hand(placement_has_cards)
	if placement_has_cards() then return end
	if not G.hand or #G.hand.cards < 2 then return end
	if InputLock.is_table_busy() then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target then return end
	G.hand:clear_selection()
	hand_shuffle_anim.animate(G.hand)
end

return M
