--[[ word_game/ui/play_effects/animate/cards.lua - Card finish, fly-off, and deal helpers ]]

local facade = require("word_game.ui.facade")
local card_fly_off = require("word_game.ui.play_effects.card_fly_off")
local definition = require("word_game.ui.play_effects.definition")
local context = require("word_game.ui.play_effects.animate.context")

local bonus_stack_ui = facade.bonus_stack_ui()

local M = {}

local function deck_api()
	return facade.deck()
end

local function finish_used_card(card, return_to_deck)
	if bonus_stack_ui.is_bonus_card(card) then
		if card.area then
			card.area:remove_card(card)
		end
		bonus_stack_ui.consume_card(card)
	elseif return_to_deck then
		if card.area then
			card.area:remove_card(card)
		end
		card_fly_off.stash_played_card(card)
	else
		if card.area then
			card.area:remove_card(card)
		end
		deck_api().destroy_card(card)
	end
end

function M.finish_used_cards(used_cards, return_to_deck)
	definition.show_bonus_flyovers(used_cards)
	local returned = false
	for _, card in ipairs(used_cards or {}) do
		if not bonus_stack_ui.is_bonus_card(card) and return_to_deck then
			returned = true
		end
		finish_used_card(card, return_to_deck)
	end
	if returned then
		deck_api().sync_deck_count_display()
	end
end

function M.run_card_return_sequence(used_cards, on_after, return_to_deck)
	definition.show_bonus_flyovers(used_cards)
	card_fly_off.fly_cards_off(used_cards, context.effects().queue_event, {
		return_to_deck = return_to_deck,
		on_complete = function()
			deck_api().sync_deck_count_display()
			if on_after then on_after() end
		end,
	})
end

function M.deal_and_refresh(on_complete)
	local function finish()
		context.effects().request_layout_refresh()
		definition.sync_hand_after_deal()
		if on_complete then on_complete() end
	end
	if deck_api().is_jumble_deck and deck_api().is_jumble_deck()
		and deck_api().needs_jumble_reshuffle and deck_api().needs_jumble_reshuffle() then
		deck_api().try_jumble_reshuffle_and_deal(finish)
		return
	end
	deck_api().deal_into_hand(facade.hand_size().get(), finish)
end

return M
