--[[ word_game/model/bonus_stack.lua - Bonus gutter card stack state and scoring ]]

local round_config = require("word_game.config.round_config")

local M = {}

M.BONUS_POINTS = 10

local stack_cards
local stack_animating = false

function M.is_bonus_card(card)
	return card and card.bonus_card
end

function M.bonus_points_for(used_cards)
	local total = 0
	for _, card in ipairs(used_cards or {}) do
		if M.is_bonus_card(card) then
			total = total + M.BONUS_POINTS
		end
	end
	return total
end

function M.is_animating()
	return stack_animating
end

function M.set_animating(active)
	stack_animating = active and true or false
end

function M.is_active()
	return stack_cards ~= nil and #stack_cards > 0
end

function M.cards()
	return stack_cards
end

function M.clear()
	stack_cards = nil
	stack_animating = false
end

function M.set_cards(cards)
	stack_cards = {}
	for _, card in ipairs(cards or {}) do
		if card and not card.REMOVED then
			stack_cards[#stack_cards + 1] = card
		end
	end
end

function M.stack_index(card)
	if not stack_cards or not card then return nil end
	for i, c in ipairs(stack_cards) do
		if c == card then return i end
	end
	return nil
end

function M.contains(card)
	return M.stack_index(card) ~= nil
end

function M.remove_card(card)
	if not stack_cards or not card then return end
	for i = #stack_cards, 1, -1 do
		if stack_cards[i] == card then
			table.remove(stack_cards, i)
			break
		end
	end
	if stack_cards and #stack_cards == 0 then
		stack_cards = nil
	end
end

function M.add_card(card)
	if not card then return end
	stack_cards = stack_cards or {}
	stack_cards[#stack_cards + 1] = card
end

function M.on_hand_start(set, hand_index)
	if round_config.is_bonus_stack_hand(set, hand_index) then
		return
	end
	M.clear()
end

function M.mark_bonus_card(card)
	if not card or card.REMOVED then return end
	card.bonus_card = true
	card.boss_temp = nil
	card.placement_locked = nil
	card.pinned = nil
	if card.ability then
		card.ability.bonus = M.BONUS_POINTS
	end
end

return M
