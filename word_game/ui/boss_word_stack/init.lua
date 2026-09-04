--[[ word_game/ui/boss_word_stack/init.lua - Bonus card stack (boss word rewards) ]]

local model = require("word_game.model.bonus_stack")
local layout = require("word_game.ui.boss_word_stack.layout")
local draw = require("word_game.ui.boss_word_stack.draw")
local animate = require("word_game.ui.boss_word_stack.animate")
local deck = require("word_game.model.cards.deck")
local LetterPalette = require("word_game.config.letter_card_palette")
local round_config = require("word_game.config.round_config")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

M.BONUS_POINTS = model.BONUS_POINTS
M.LEFT_WINDOW_MARGIN = layout.LEFT_WINDOW_MARGIN
M.STACK_Y_LIFT_PX = layout.STACK_Y_LIFT_PX

function M.is_animating()
	return model.is_animating()
end

function M.is_bonus_card(card)
	return model.is_bonus_card(card)
end

function M.detach(card)
	if not card then return end
	if G.placement_table and G.placement_table.on_remove_card then
		G.placement_table:on_remove_card(card)
	end
	if card.area and card.area.remove_card then
		card.area:remove_card(card)
	end
	if card.remove_from_area then
		card:remove_from_area()
	else
		card.area = nil
		card.parent = nil
	end
	if card.states and card.states.drag then
		card.states.drag.can = true
		card.states.drag.is = false
	end
	if card.states and card.states.collide then
		card.states.collide.can = true
	end
	if card.states then
		card.states.visible = true
	end
	if card.set_selected then
		card:set_selected(false)
	end
	if card.T then
		card.T.r = 0
	end
end

function M.is_active()
	return model.is_active()
end

function M.cards()
	return model.cards()
end

function M.set_cards(cards)
	M.stage_cards(cards)
end

function M.clear()
	model.clear()
end

function M.stage_cards(cards)
	local staged = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			staged[#staged + 1] = card
		end
	end
	model.set_cards(staged)
	model.set_animating(#staged > 0)
end

function M.on_hand_start(set, hand_index)
	model.on_hand_start(set, hand_index)
	if round_config.is_bonus_stack_hand(set, hand_index) and not model.is_animating() then
		M.sync_positions()
	end
end

local function card_letter(card)
	return (card.ability and card.ability.letter)
		or (card.config and card.config.card and card.config.card.letter)
end

function M.apply_gold_bonus_face(card)
	local letter = card_letter(card)
	if not letter then return end
	local color = LetterPalette.BONUS_FACE_COLOR
	local front = deck.front(letter, color)
	if front and card.apply_face then
		deck.tag_card(card, letter, color)
		card:apply_face(front, false)
	end
	if card.bonus_card then
		card.dissolve = 0
		card.dissolve_wipe = 0
		card.dissolve_colours = nil
	end
end

function M.become_bonus_card(card)
	if not card or card.REMOVED then return end
	model.mark_bonus_card(card)
	M.apply_gold_bonus_face(card)
end

local function reconcile_bonus_faces()
	for _, card in ipairs(model.cards() or {}) do
		if card and card.bonus_card and not card.REMOVED then
			M.apply_gold_bonus_face(card)
		end
	end
end

function M.stack_y_lift()
	return layout.stack_y_lift()
end

function M.stack_layout()
	return layout.stack_layout()
end

function M.clears_gameplay_bounds()
	return layout.clears_gameplay_bounds()
end

function M.target_position(index)
	return layout.target_position(index)
end

function M.stack_index(card)
	return model.stack_index(card)
end

function M.contains(card)
	return model.contains(card)
end

function M.sync_positions()
	if not model.cards() or model.is_animating() then return end
	local placement = G.placement_table and G.placement_table.area
	for i, card in ipairs(model.cards() or {}) do
		if card and not card.REMOVED then
			if card.area == G.hand and M.is_bonus_card(card) then
				M.return_card(card)
			elseif card.area == placement then
				-- Bonus cards placed in the puzzle row keep their slot layout.
			else
				if card.area then
					M.detach(card)
				end
				local tx, ty = M.target_position(i)
				if card.hard_set_T then
					card:hard_set_T(tx, ty, card.T.w, card.T.h)
				else
					card.T.x, card.T.y = tx, ty
				end
				if card.states and card.states.drag then
					card.states.drag.can = true
				end
				if card.states and card.states.collide then
					card.states.collide.can = true
				end
				if card.states then
					card.states.visible = true
				end
			end
		end
	end
	reconcile_bonus_faces()
end

function M.promote_to_bonus(cards)
	model.set_animating(false)
	local promoted = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			M.become_bonus_card(card)
			promoted[#promoted + 1] = card
		end
	end
	model.set_cards(promoted)
	model.set_animating(false)
	M.sync_positions()
end

function M.animate_cards_to_stack(queue_event, easing_mod, opts)
	animate.animate_cards_to_stack(queue_event, easing_mod, opts)
end

function M.finalize_for_bonus_hand(wr)
	local j = wr and wr.jumble
	if j and j.boss_cards then
		local deck_mod = require("word_game.model.cards.deck")
		for _, card in ipairs(j.boss_cards) do
			if card and not card.REMOVED and not card.bonus_card then
				deck_mod.destroy_card(card)
			end
		end
		j.boss_cards = nil
	end
	if not model.is_animating() then
		M.sync_positions()
	end
end

function M.remove_card(card)
	model.remove_card(card)
	if model.is_active() then
		M.sync_positions()
	end
end

function M.return_card(card)
	return layout.return_card(card)
end

function M.point_in_stack(x, y)
	return layout.point_in_stack(x, y)
end

function M.drop_in_gutter(session, x, y)
	return layout.drop_in_gutter(session, x, y)
end

function M.bonus_points_for(used_cards)
	return model.bonus_points_for(used_cards)
end

local function try_award_gutter_perk()
	if M.is_active() then return end
	local perk_stamp = WORD_GAME and WORD_GAME.PerkStamp
	if not perk_stamp then return end
	local perk_model = require("word_game.model.perk")
	local rolled = perk_model.roll_stamp_perk()
	if not rolled then return end
	if not perk_stamp.play(rolled) then
		perk_stamp.queue(rolled)
	end
	word_feedback.show_screen_centered("Perk earned!", G.C and G.C.GOLD or { 1, 0.85, 0.2, 1 }, 1.1)
end

function M.consume_card(card)
	model.remove_card(card)
	if card.area and card.area.remove_card then
		card.area:remove_card(card)
	elseif card.remove_from_area then
		card:remove_from_area()
	end
	if card.start_dissolve then
		card:start_dissolve()
		try_award_gutter_perk()
		return
	end
	local deck_mod = require("word_game.model.cards.deck")
	deck_mod.destroy_card(card)
	try_award_gutter_perk()
end

function M.gutter_pixels(layout_arg)
	return layout.gutter_pixels(layout_arg)
end

function M.draw_shadow()
	draw.draw_shadow(layout)
end

function M.draw_pass()
	draw.draw_pass(layout)
end

return M
