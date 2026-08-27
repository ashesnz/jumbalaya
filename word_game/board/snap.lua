--[[ word_game.board/snap.lua - Placement-row drag helpers and jumble slot snap. ]]

local layout = require "word_game.board.layout"
local jumble_geometry = require "word_game.board.jumble_geometry"
local shimmer = require "word_game.board.shimmer"
local placement_word = require "word_game.model.placement_word"

local M = {}

function M.remove_from_area(area, card)
	if not area or not area.cards then return end
	for i = #area.cards, 1, -1 do
		if area.cards[i] == card then
			card:remove_from_area()
			table.remove(area.cards, i)
			area:remove_selection(card, true)
			return true
		end
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

function M.hand_limit()
	return G.TABLE_HAND_SIZE or (G.hand and G.hand.config.card_limit) or 7
end

function M.card_on_placement(session, card)
	return session.area and card and card.area == session.area
end

function M.point_in_hand(x, y)
	if not G.hand then return false end
	local pad_x = G.CARD_W * 0.15
	local pad_y = G.CARD_H * 0.2
	return x >= G.hand.T.x - pad_x
		and x <= G.hand.T.x + G.hand.T.w + pad_x
		and y >= G.hand.T.y - pad_y
		and y <= G.hand.T.y + G.hand.T.h + pad_y
end

function M.point_in_return_zone(session, x, y)
	if M.point_in_hand(x, y) then return true end
	local area = session and session.area
	if not area or not G.hand then return false end
	local top = area.T.y + area.T.h
	local bottom = G.hand.T.y
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
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if not jumble or not jumble.is_active() then return false end
	local j = jumble.state()
	if j and j.boss_puzzle_hidden then return false end

	local area = session.area
	if not area or not card or card.REMOVED then return false end

	local from_area = card.area
	if from_area and from_area ~= area then
		from_area:remove_card(card)
	elseif from_area == area then
		jumble.remove_card_from_blanks(card)
	end
	if G.deck and G.deck ~= area then
		M.drop_from_area_list(G.deck, card)
	end
	if G.hand and G.hand ~= area and G.hand ~= from_area then
		M.drop_from_area_list(G.hand, card)
	end

	local cx = card.T.x + card.T.w / 2
	local slot_i, insert_pos = jumble.blank_slot_index_for_x(session, cx)
	if not slot_i then
		slot_i = jumble.first_empty_blank()
		insert_pos = nil
	end
	if not slot_i then
		if from_area == area or (from_area and from_area == G.hand) then
			if G.hand then
				G.hand:emplace(card)
				G.hand:relayout()
			end
		end
		jumble_geometry.relayout(session)
		area:hard_set_cards()
		return false
	end

	jumble.assign_card_to_blank(slot_i, card, insert_pos)
	card:set_card_area(area)
	card.placement_locked = nil
	card.states.drag.can = true
	card.states.collide.can = true
	card.states.drag.is = false
	card.selected = false

	shimmer.start_card(session, card)
	jumble_geometry.relayout(session)
	area:hard_set_cards()

	placement_word.refresh_from_jumble_slots(jumble.state().slots)
	if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync_visibility then
		WORD_GAME.HandShuffle.sync_visibility()
	end
	return true
end

function M.return_to_hand(session, card)
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if not jumble or not jumble.is_active() then return false end
	if not G.hand or not M.card_on_placement(session, card) then return false end
	jumble.remove_card_from_blanks(card)
	G.hand:emplace(card)
	G.hand:relayout()
	G.hand:snap_VT()
	G.hand:hard_set_cards()
	jumble_geometry.relayout(session)
	session.area:hard_set_cards()
	placement_word.clear()
	return true
end

function M.try_snap(session, card)
	if not (WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.is_active()) then
		return
	end

	local area = session.area
	if not area or not card or card.REMOVED then return end

	local cx = card.T.x + card.T.w / 2
	local cy = card.T.y + card.T.h / 2
	local in_row = layout.point_in_area(session, cx, cy)
	local j = WORD_GAME.Jumble.state()
	local from_blank = card_in_jumble_slots(j, card)

	if (from_blank or M.card_on_placement(session, card)) and M.point_in_return_zone(session, cx, cy) then
		if M.return_to_hand(session, card) then
			play_sfx("card_slide1", nil, 0.8)
			if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync_visibility then
				WORD_GAME.HandShuffle.sync_visibility()
			end
			return
		end
	elseif in_row then
		local placed = M.place_in_row(session, card)
		if placed then
			play_sfx("card_drop", 0.9, 0.8)
		elseif card.area then
			card.area:relayout()
		end
	elseif from_blank or card.area == area then
		jumble_geometry.relayout(session)
		area:hard_set_cards()
	elseif card.area then
		card.area:relayout()
	end

	-- Gold lock-in flash: fire whenever a drop over the row leaves the card
	-- placed in it, whatever internal path put it there.
	if in_row and M.card_on_placement(session, card) then
		shimmer.start_card(session, card)
	end
end

return M
