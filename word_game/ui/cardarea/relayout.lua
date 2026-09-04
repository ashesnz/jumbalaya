--[[ word_game/ui/cardarea/relayout.lua - Slot math and per-type card positioning ]]

local hand = require("word_game.ui.cardarea.hand")
local deck = require("word_game.ui.cardarea.deck")
local placement = require("word_game.ui.cardarea.placement")

local M = {}

local function row_progress(slot, count, max_slots)
	local span = math.max(max_slots - 1, 1)
	return (slot - 1) / span - 0.5 * (count - max_slots) / span
end

local function slot_x(area, card, k, count, max_slots, span_width)
	local width = span_width or area.T.w
	local x = area.T.x + (width - area.card_w) * row_progress(k, count, max_slots)
		+ 0.5 * (area.card_w - card.T.w)
	if span_width then x = x + (area.T.w - width) / 2 end
	return x
end

local function even_x(area, card, k, count)
	if count > 1 then
		return area.T.x + (area.T.w - area.card_w) * ((k - 1) / (count - 1)) + 0.5 * (area.card_w - card.T.w)
	end
	return area.T.x + area.T.w / 2 - area.card_w / 2 + 0.5 * (area.card_w - card.T.w)
end

local function selection_lift(card, scale)
	if card.selected then return G.HIGHLIGHT_H * (scale or 1) end
	return 0
end

local function fan_tilt(k, count, amplitude, phase_x, phase_y)
	local lean = amplitude * (-count / 2 - 0.5 + k) / count
	local wobble = 0.02 * math.sin(2 * G.TIMERS.REAL + phase_x + (phase_y or 0))
	return lean + wobble
end

local function row_bob(x)
	return 0.03 * math.sin(0.666 * G.TIMERS.REAL + x)
end

local function apply_parallax(card)
	card.T.x = card.T.x + card.shadow_parallax.x / 30
end

local function sort_by_left_edge(cards)
	table.sort(cards, function(a, b) return a.T.x + a.T.w / 2 < b.T.x + b.T.w / 2 end)
end

function M.relayout(area, face_down_in_pile)
	if not area.cards then return end
	if (area == G.hand or area == G.deck or area == G.discard) and G.view_deck and G.view_deck[1] and G.view_deck[1].cards then return end

	deck.relayout(area)
	hand.relayout(area)

	local count = #area.cards
	local layout = area.config.type

	if layout == 'discard' then
		for k, card in ipairs(area.cards) do
			face_down_in_pile(card)
			if not card.states.drag.is then
				card.T.x = area.T.x + (area.T.w - card.T.w) * card.discard_pos.x
				card.T.y = area.T.y + (area.T.h - card.T.h) * card.discard_pos.y
				card.T.r = card.discard_pos.r
			end
		end
	end

	if layout == 'title' or (layout == 'perk' and count == 1) then
		for k, card in ipairs(area.cards) do
			if not card.states.drag.is then
				local max_slots = math.max(count, area.config.temp_limit)
				card.T.r = fan_tilt(k, count, 0.2, card.T.x)
				card.T.x = slot_x(area, card, k, count, max_slots)
				card.T.y = area.T.y + area.T.h / 2 - card.T.h / 2 - selection_lift(card)
					+ row_bob(card.T.x)
					+ math.abs(0.5 * (-count / 2 + k - 0.5) / count)
					- (count > 1 and 0.2 or 0)
				apply_parallax(card)
			end
		end
		sort_by_left_edge(area.cards)
	end

	if layout == 'perk' and count > 1 then
		local span_width = math.max(area.T.w, 3.2)
		for k, card in ipairs(area.cards) do
			if not card.states.drag.is then
				local max_slots = math.max(count, area.config.temp_limit)
				local side = (k % 2 == 1) and -1 or 1
				card.T.r = fan_tilt(k, count, 0.2, card.T.x, card.T.y) + side * 0.08
				card.T.x = slot_x(area, card, k, count, max_slots, span_width) - side * 0.27
				card.T.y = area.T.y + area.T.h / 2 - card.T.h / 2 - selection_lift(card)
					+ row_bob(card.T.x)
					+ math.abs(0.5 * (-count / 2 + k - 0.5) / count)
					- (count > 1 and 0.2 or 0)
				apply_parallax(card)
			end
		end
		table.sort(area.cards, function(a, b) return a.ability.order < b.ability.order end)
	end

	if layout == 'shop' then
		for k, card in ipairs(area.cards) do
			if not card.states.drag.is then
				local max_slots = math.max(count, area.config.temp_limit)
				card.T.r = 0
				card.T.x = slot_x(area, card, k, count, max_slots)
				if area.config.card_limit == 1 then
					card.T.x = card.T.x + 0.5 * (area.T.w - card.T.w)
				end
				card.T.y = area.T.y + area.T.h / 2 - card.T.h / 2 - selection_lift(card)
				apply_parallax(card)
			end
		end
		sort_by_left_edge(area.cards)
	end

	if layout == 'title_2' then
		for k, card in ipairs(area.cards) do
			if not card.states.drag.is then
				card.T.r = fan_tilt(k, count, 0.1, card.T.x)
				if count > 2 or (count > 1 and area.config.spread) then
					card.T.x = even_x(area, card, k, count)
				elseif count > 1 then
					card.T.x = area.T.x + (area.T.w - area.card_w) * ((k - 0.5) / count) + 0.5 * (area.card_w - card.T.w)
				else
					card.T.x = even_x(area, card, k, count)
				end
				card.T.y = area.T.y + area.T.h / 2 - card.T.h / 2 - selection_lift(card, 0.5)
					+ row_bob(card.T.x)
				apply_parallax(card)
			end
		end
		table.sort(area.cards, function(a, b)
			return a.T.x + a.T.w / 2 - 100 * (a.pinned and a.sort_id or 0)
				< b.T.x + b.T.w / 2 - 100 * (b.pinned and b.sort_id or 0)
		end)
	end

	if layout == 'usable' then
		for k, card in ipairs(area.cards) do
			if not card.states.drag.is then
				card.T.x = even_x(area, card, k, count)
				card.T.y = area.T.y + area.T.h / 2 - card.T.h / 2 - selection_lift(card)
					+ (not card.selected and 0.05 * math.sin(3.332 * G.TIMERS.REAL + card.T.x) or 0)
				apply_parallax(card)
			end
		end
		sort_by_left_edge(area.cards)
	end

	placement.relayout(area)

	for k, card in ipairs(area.cards) do
		card.slot = k
	end
	if area.children.view_deck then
		area.children.view_deck:set_role{major = area.cards[1] or area}
	end
end

return M
