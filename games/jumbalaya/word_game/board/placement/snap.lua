--[[ word_game.board.placement.snap - Placement-row drag helpers and jumble slot snap. ]]

local layout = require "word_game.board.placement.layout"
local jumble_geometry = require "word_game.board.jumble.geometry"
local shimmer = require "word_game.board.placement.shimmer"
local BonusStack = require "word_game.model.jumble.bonus_stack"
local TableAreas = require "word_game.model.table_areas"
local piles = require("word_game.model.piles")

local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end

local PlacementWord = require("word_game.model.jumble.placement_word")
local Jumble = require("word_game.model.jumble")

local function placement_word()
	return PlacementWord
end
local bonus_gutter = require "word_game.board.bonus.gutter"

local M = {}

local modifier_feedback_hook

function M.bind_modifier_feedback(hook)
	modifier_feedback_hook = hook
end

local function show_modifier_feedback(card)
	if card and modifier_feedback_hook then
		modifier_feedback_hook(card)
	end
end

function M.drop_from_area_list(area, card)
	if not area or not area.cards then return end
	for i = #area.cards, 1, -1 do
		if area.cards[i] == card then
			table.remove(area.cards, i)
		end
	end
end

function M.clear_card(session, card)
	if session.card_shimmer_t then
		session.card_shimmer_t[card] = nil
	end
	card.placement_locked = nil
	card.pinned = nil
end

function M.card_on_placement(session, card)
	return session.area and card and card.area == session.area
end

function M.point_in_hand(x, y)
	local dealt = TableAreas.dealt_letters()
	if not dealt or not dealt.T then return false end
	local pad_x = (g().CARD_W or 1) * 0.15
	local pad_y = (g().CARD_H or 1.4) * 0.2
	return x >= dealt.T.x - pad_x
		and x <= dealt.T.x + dealt.T.w + pad_x
		and y >= dealt.T.y - pad_y
		and y <= dealt.T.y + dealt.T.h + pad_y
end

local function bonus_origin_slot(card)
	local jumble = Jumble
	if jumble and jumble.slot_for_card then
		return jumble.slot_for_card(card)
	end
	return nil, nil
end

function M.restore_bonus_card(session, card, origin_slot, origin_insert)
	if not BonusStack.is_bonus_card(card) then return false end
	local dealt = TableAreas.dealt_letters()
	local draw = TableAreas.draw_pile()
	if dealt then
		if dealt.remove_card then dealt:remove_card(card) else M.drop_from_area_list(dealt, card) end
	end
	if draw then
		if draw.remove_card then draw:remove_card(card) else M.drop_from_area_list(draw, card) end
	end

	local jumble = Jumble
	if origin_slot and jumble and jumble.assign_card_to_blank then
		if jumble.assign_card_to_blank(origin_slot, card, origin_insert) then
			if session and session.area then
				jumble_geometry.relayout(session)
				session.area:hard_set_cards()
			end
			placement_word().refresh_from_jumble_slots(jumble.state().slots)
			show_modifier_feedback(card)
			return true
		end
	end

	bonus_gutter.return_card(card)
	if session and session.area then
		jumble_geometry.relayout(session)
		session.area:hard_set_cards()
	end
	return true
end

function M.point_in_return_zone(session, x, y)
	if BonusStack.is_active() and bonus_gutter.point_in_stack(x, y) then
		return true
	end
	if M.point_in_hand(x, y) then return true end
	local area = session and session.area
	local dealt = TableAreas.dealt_letters()
	if not area or not dealt or not dealt.T then return false end
	local top = area.T.y + area.T.h
	local bottom = dealt.T.y
	if y < top or y > bottom then return false end
	local felt = get_table_felt_rect and get_table_felt_rect()
	if felt then
		return x >= felt.x and x <= felt.x + felt.w
	end
	return x >= area.T.x and x <= area.T.x + area.T.w
end

local function card_in_jumble_slots(j, card)
	if not j or not j.slots then return false end
	for _, slot in ipairs(j.slots) do
		if slot.card == card then return true end
		if slot.kind == "span" then
			for _, span_card in ipairs(slot.cards or {}) do
				if span_card == card then return true end
			end
		end
	end
	return false
end

function M.place_in_row(session, card)
	local jumble = Jumble
	if not jumble or not jumble.is_active() then return false end
	local j = jumble.state()
	if j and j.boss_puzzle_hidden then return false end

	local area = session.area
	if not area or not card or card.REMOVED then return false end

	local origin_slot, origin_insert = bonus_origin_slot(card)
	local from_area = card.area
	local from_bonus = BonusStack.contains(card)
	local dealt = TableAreas.dealt_letters()
	local draw = TableAreas.draw_pile()
	if from_area and from_area ~= area then
		if from_area.remove_card then from_area:remove_card(card) else M.drop_from_area_list(from_area, card) end
	elseif from_area == area then
		jumble.remove_card_from_blanks(card)
	end
	if draw and draw ~= area then
		if draw.remove_card then draw:remove_card(card) else M.drop_from_area_list(draw, card) end
	end
	if dealt and dealt ~= area and dealt ~= from_area then
		if dealt.remove_card then dealt:remove_card(card) else M.drop_from_area_list(dealt, card) end
	end

	local cx = card.T.x + card.T.w / 2
	local slot_i, insert_pos = jumble.blank_slot_index_for_x(session, cx)
	if not slot_i then
		slot_i = jumble.first_empty_blank()
		insert_pos = nil
	end
	if not slot_i then
		if BonusStack.is_bonus_card(card) then
			M.restore_bonus_card(session, card, origin_slot, origin_insert)
		elseif from_area == area or (from_area and dealt and from_area == dealt) then
			if dealt then
				if dealt.emplace then dealt:emplace(card) end
				if dealt.relayout then dealt:relayout() end
			end
		elseif from_bonus then
			bonus_gutter.return_card(card)
		end
		jumble_geometry.relayout(session)
		area:hard_set_cards()
		return false
	end

	card.placement_locked = nil
	card.states.drag.can = true
	card.states.collide.can = true
	card.states.drag.is = false
	card.selected = false

	jumble.assign_card_to_blank(slot_i, card, insert_pos)
	card:set_card_area(area)

	piles.move_card({
		card = card,
		card_id = card.id or card.letter_card_id,
		from_pile = card.pile_id or (from_bonus and "bonus") or "hand",
		to_pile = "pattern",
		slot_index = slot_i,
	})

	shimmer.start_card(session, card)
	jumble_geometry.relayout(session)
	area:hard_set_cards()

	placement_word().refresh_from_jumble_slots(jumble.state().slots)
	show_modifier_feedback(card)
	return true
end

function M.return_to_hand(session, card)
	local jumble = Jumble
	if not jumble or not jumble.is_active() then return false end
	local dealt = TableAreas.dealt_letters()
	if BonusStack.is_bonus_card(card) then
		if not M.card_on_placement(session, card) then return false end
		bonus_gutter.return_card(card)
		jumble.remove_card_from_blanks(card)
		jumble_geometry.relayout(session)
		session.area:hard_set_cards()
		placement_word().clear()
		return true
	end
	if not dealt or not M.card_on_placement(session, card) then return false end
	jumble.remove_card_from_blanks(card)
	if dealt.emplace then dealt:emplace(card) end
	if dealt.relayout then dealt:relayout() end
	if dealt.snap_VT then dealt:snap_VT() end
	if dealt.hard_set_cards then dealt:hard_set_cards() end

	piles.move_card({
		card = card,
		card_id = card.id or card.letter_card_id,
		from_pile = card.pile_id or "pattern",
		to_pile = "hand",
	})

	jumble_geometry.relayout(session)
	session.area:hard_set_cards()
	placement_word().clear()
	return true
end

---@return table effects Optional UI reactions for the caller (e.g. hand_shuffle_sync).
function M.try_snap(session, card)
	local effects = {}
	if not (Jumble and Jumble.is_active()) then
		return effects
	end

	local area = session.area
	if not area or not card or card.REMOVED then return effects end

	local cx = card.T.x + card.T.w / 2
	local cy = card.T.y + card.T.h / 2
	local in_row = layout.point_in_area(session, cx, cy)
	local j = Jumble.state()
	local from_blank = card_in_jumble_slots(j, card)

	if BonusStack.is_bonus_card(card) then
		local origin_slot, origin_insert = bonus_origin_slot(card)
		if in_row then
			local placed = M.place_in_row(session, card)
			if placed then
				play_sfx("card_drop", 0.9, 0.8)
				effects.hand_shuffle_sync = true
			end
			if in_row and M.card_on_placement(session, card) then
				shimmer.start_card(session, card)
			end
			return effects
		end

		local function finish_bonus_return()
			placement_word().clear()
			play_sfx("card_slide1", nil, 0.8)
			effects.hand_shuffle_sync = true
		end

		local function leave_placement_slot()
			if from_blank or M.card_on_placement(session, card) then
				Jumble.remove_card_from_blanks(card)
			end
		end

		if M.point_in_hand(cx, cy) then
			leave_placement_slot()
			M.restore_bonus_card(session, card, origin_slot, origin_insert)
			finish_bonus_return()
			return effects
		end

		if from_blank or M.card_on_placement(session, card) then
			if BonusStack.is_active() and cx < area.T.x then
				bonus_gutter.return_card(card)
				if from_blank or M.card_on_placement(session, card) then
					Jumble.remove_card_from_blanks(card)
				end
				if session and session.area then
					jumble_geometry.relayout(session)
					session.area:hard_set_cards()
				end
			else
				leave_placement_slot()
				M.restore_bonus_card(session, card, origin_slot, origin_insert)
			end
			finish_bonus_return()
			return effects
		end

		bonus_gutter.return_card(card)
		return effects
	end

	if (from_blank or M.card_on_placement(session, card) or BonusStack.contains(card))
		and M.point_in_return_zone(session, cx, cy) then
		if M.return_to_hand(session, card) then
			play_sfx("card_slide1", nil, 0.8)
			effects.hand_shuffle_sync = true
			return effects
		end
	elseif in_row then
		local placed = M.place_in_row(session, card)
		if placed then
			play_sfx("card_drop", 0.9, 0.8)
			effects.hand_shuffle_sync = true
		elseif card.area then
			card.area:relayout()
		end
	elseif from_blank or card.area == area then
		jumble_geometry.relayout(session)
		area:hard_set_cards()
	elseif BonusStack.contains(card) then
		bonus_gutter.return_card(card)
	elseif card.area then
		card.area:relayout()
	end

	-- Gold lock-in flash: fire whenever a drop over the row leaves the card
	-- placed in it, whatever internal path put it there.
	if in_row and M.card_on_placement(session, card) then
		shimmer.start_card(session, card)
	end
	return effects
end

return M
