--[[ word_game/ui/perks/bonus_stack/init.lua - Bonus gutter presentation (boss-word rewards) ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local facade = require("word_game.ui.facade")
local layout = require("word_game.ui.perks.bonus_stack.layout")
local draw = require("word_game.ui.perks.bonus_stack.draw")
local animate = require("word_game.ui.perks.bonus_stack.animate")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")
local round_config = require("jumbalaya_core.config.gameplay.round")
local word_feedback = require("word_game.ui.feedback.word_feedback")

local function bonus_stack_model()
	return facade.bonus_stack()
end

local function deck_api()
	return facade.deck()
end

local M = {}

M.BONUS_POINTS = bonus_stack_model().BONUS_POINTS
M.LEFT_WINDOW_MARGIN = layout.LEFT_WINDOW_MARGIN
M.STACK_Y_LIFT_PX = layout.STACK_Y_LIFT_PX

local function forward_model(name)
	return function(...)
		return bonus_stack_model()[name](...)
	end
end

local function forward_layout(name)
	return function(...)
		return layout[name](...)
	end
end

for _, name in ipairs({
	"is_animating",
	"is_bonus_card",
	"is_active",
	"cards",
	"clear",
	"stack_index",
	"contains",
	"bonus_points_for",
}) do
	M[name] = forward_model(name)
end

for _, name in ipairs({
	"stack_y_lift",
	"stack_layout",
	"clears_gameplay_bounds",
	"target_position",
	"point_in_stack",
	"drop_in_gutter",
	"gutter_pixels",
	"return_card",
}) do
	M[name] = forward_layout(name)
end

function M.detach(card)
	if not card then return end
	if runtime().pattern_row and runtime().pattern_row.on_remove_card then
		runtime().pattern_row:on_remove_card(card)
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

function M.set_cards(cards)
	M.stage_cards(cards)
end

function M.stage_cards(cards)
	local staged = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			staged[#staged + 1] = card
		end
	end
	bonus_stack_model().set_cards(staged)
	bonus_stack_model().set_animating(#staged > 0)
end

function M.on_hand_start(set, hand_index)
	bonus_stack_model().on_hand_start(set, hand_index)
	if round_config.is_bonus_stack_hand(set, hand_index) and not M.is_animating() then
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
	local front = deck_api().front(letter, color)
	if front and card.apply_face then
		deck_api().tag_card(card, letter, color)
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
	bonus_stack_model().mark_bonus_card(card)
	M.apply_gold_bonus_face(card)
end

local function reconcile_bonus_faces()
	for _, card in ipairs(M.cards() or {}) do
		if card and card.bonus_card and not card.REMOVED then
			M.apply_gold_bonus_face(card)
		end
	end
end

function M.sync_positions()
	if not M.cards() or M.is_animating() then return end
	local placement = runtime().pattern_row and runtime().pattern_row.area
	for i, card in ipairs(M.cards() or {}) do
		if card and not card.REMOVED then
			if card.area == runtime().dealt_letters and M.is_bonus_card(card) then
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
	bonus_stack_model().set_animating(false)
	local promoted = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			M.detach(card)
			M.become_bonus_card(card)
			promoted[#promoted + 1] = card
		end
	end
	bonus_stack_model().set_cards(promoted)
	bonus_stack_model().set_animating(false)
	M.sync_positions()
end

function M.animate_cards_to_stack(queue_event, easing_mod, opts)
	animate.animate_cards_to_stack(queue_event, easing_mod, opts)
end

function M.finalize_for_bonus_hand(wr)
	local j = wr and wr.jumble
	if j and j.boss_cards then
		local deck = deck_api()
		for _, card in ipairs(j.boss_cards) do
			if card and not card.REMOVED and not card.bonus_card then
				deck.destroy_card(card)
			end
		end
		j.boss_cards = nil
	end
	if not M.is_animating() then
		M.sync_positions()
	end
end

function M.remove_card(card)
	bonus_stack_model().remove_card(card)
	if M.is_active() then
		M.sync_positions()
	end
end

local function try_award_gutter_perk()
	if M.is_active() then return end
	local perk_stamp = WORD_GAME_UI.PerkStamp
	if not perk_stamp then return end
	local rolled = facade.perks_registry().roll_stamp_perk()
	if not rolled then return end
	if not perk_stamp.play(rolled) then
		perk_stamp.queue(rolled)
	end
	word_feedback.show_screen_centered("Perk earned!", runtime().C and runtime().C.GOLD or { 1, 0.85, 0.2, 1 }, 1.1)
end

function M.consume_card(card)
	bonus_stack_model().remove_card(card)
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
	deck_api().destroy_card(card)
	try_award_gutter_perk()
end

function M.draw_pass()
	draw.draw_pass(layout)
end

animate.bind_stack(M)

return M
