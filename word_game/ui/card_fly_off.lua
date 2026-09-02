--[[ word_game/ui/card_fly_off.lua - Played cards fly off-screen instead of the discard bin ]]

local boss_word_stack = require("word_game.ui.boss_word_stack")
local deck = require("word_game.model.cards.deck")

local M = {}

local FLY_DURATION = 0.38
local STAGGER = 0.09

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

local function sync_card_transform(card)
	if card.hard_set_T then
		card:hard_set_T(card.T.x, card.T.y, card.T.w, card.T.h)
	end
	if card.snap_VT then
		card:snap_VT()
	end
end

local function window_left_x()
	return -((G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0)
end

local function detach_card(card)
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
		card.states.drag.can = false
		card.states.drag.is = false
	end
	if card.states then
		card.states.visible = true
	end
	if card.set_container and G.ROOM then
		card:set_container(G.ROOM)
	end
end

function M.stash_played_card(card)
	if card.area and card.area.remove_card then
		card.area:remove_card(card)
	end
	card.REMOVED = nil
	card.played_pool = true
	if card.states then
		card.states.visible = false
		if card.states.drag then card.states.drag.can = false end
		if card.states.collide then card.states.collide.can = false end
		if card.states.hover then card.states.hover.can = false end
		if card.states.click then card.states.click.can = false end
	end
	if G.discard and G.discard.emplace then
		G.discard:emplace(card)
	end
end

local function fly_one_card(queue_event, card, index, count, return_to_deck, on_card_done)
	if boss_word_stack.is_bonus_card(card) then
		boss_word_stack.consume_card(card)
		if on_card_done then on_card_done() end
		return
	end

	if not return_to_deck then
		deck.destroy_card(card)
		if on_card_done then on_card_done() end
		return
	end

	local can_animate = queue_event and G.TIMELINE and G.TIMELINE.enqueue and G.TIMERS and card.T
	if not can_animate then
		if card.area and card.area.remove_card then
			card.area:remove_card(card)
		end
		M.stash_played_card(card)
		if on_card_done then on_card_done() end
		return
	end

	detach_card(card)
	local sx, sy = card.T.x, card.T.y
	local sw = card.T.w or (G.CARD_W or 1)
	local tx = window_left_x() - sw * 0.6
	local ty = sy + (index - (count + 1) * 0.5) * 0.04
	local started = (G.TIMERS and G.TIMERS.REAL) or 0

	if play_sfx then
		play_sfx("card_slide1", 0.85 + (index / math.max(1, count)) * 0.2, 0.6)
	end

	queue_event(Tween({
		mode = "window",
		timer = "REAL",
		delay = FLY_DURATION,
		blocking = true,
		func = function()
			local now = (G.TIMERS and G.TIMERS.REAL) or (started + FLY_DURATION)
			local u = FLY_DURATION > 0 and math.min(1, (now - started) / FLY_DURATION) or 1
			local e = smoothstep(u)
			card.T.x = sx + (tx - sx) * e
			card.T.y = sy + (ty - sy) * e
			sync_card_transform(card)
			if u >= 1 then
				M.stash_played_card(card)
				if on_card_done then on_card_done() end
			end
			return u >= 1
		end,
	}))
end

function M.fly_cards_off(cards, queue_event, opts)
	opts = opts or {}
	local return_to_deck = opts.return_to_deck
	local on_complete = opts.on_complete
	local list = cards or {}
	local count = #list

	if count == 0 then
		if on_complete then on_complete() end
		return
	end

	local finished = 0
	local function card_done()
		finished = finished + 1
		if finished >= count and on_complete then
			on_complete()
		end
	end

	for index, card in ipairs(list) do
		local delay = (index == 1) and 0.04 or STAGGER
		local can_animate = queue_event and G.TIMELINE and G.TIMELINE.enqueue and G.TIMERS and card.T
		if can_animate then
			queue_event(Tween({
				mode = "delayed",
				timer = "REAL",
				delay = delay,
				blocking = true,
				func = function()
					fly_one_card(queue_event, card, index, count, return_to_deck, card_done)
					return true
				end,
			}))
		else
			fly_one_card(nil, card, index, count, return_to_deck, card_done)
		end
	end
end

return M
