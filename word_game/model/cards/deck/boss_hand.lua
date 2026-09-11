--[[ word_game/model/cards/deck/boss_hand.lua - Boss-hand deal choreography ]]

local Scheduler = require "app.effects.timeline_scheduler"
local CardMotion = require "app.effects.card_motion"
local LetterPalette = require "word_game.config.visuals.letter_card_palette"
local game_access = require("word_game.model.game_access")

return function(deck_module, context)
	return function(letters, on_complete, opts)
		opts = opts or {}
		local stagger = opts.fast and 0.04 or 0.1
		local finish_delay = opts.fast and 0.06 or 0.2
		if not G.dealt_letters or not letters or #letters == 0 then
			if on_complete then on_complete() end
			return
		end
		deck_module.clear_hand_and_placement()
		local wr = game_access.word_round()
		local j = wr and wr.jumble
		j.boss_cards = {}
		for i, letter in ipairs(letters) do
			local card = deck_module.create_letter_card(letter, LetterPalette.DEFAULT_FACE_COLOR)
			card.boss_temp = true
			for pi = #(G.letter_inventory or {}), 1, -1 do
				if G.letter_inventory[pi] == card then
					table.remove(G.letter_inventory, pi)
					break
				end
			end
			j.boss_cards[#j.boss_cards + 1] = card
			G.draw_pile:emplace(card)
			if G.TIMELINE and G.TIMELINE.enqueue then
				Scheduler.add{
					mode = "window",
					delay = (i - 1) * stagger,
					blocking = true,
					func = function()
						CardMotion.move{from = G.draw_pile, to = G.dealt_letters, percent = 50, direction = "up", stay_flipped = false, card = card, delay = 0.08}
						return true
					end,
				}
			elseif context.fly_from_deck_to_hand then
				context.fly_from_deck_to_hand(card)
			else
				G.draw_pile:remove_card(card)
				G.dealt_letters:emplace(card)
			end
		end
		local finish = function()
			local wr_finish = game_access.word_round()
			local j_finish = wr_finish and wr_finish.jumble
			if not (j_finish and j_finish.boss_puzzle_hidden)
				and G.pattern_row and G.pattern_row.apply_screen_position then
				G.pattern_row:apply_screen_position()
			end
			if G.dealt_letters then
				G.dealt_letters:set_ranks()
				G.dealt_letters:relayout()
				G.dealt_letters:snap_VT()
				G.dealt_letters:hard_set_cards()
			end
			deck_module.sync_deck_count_display()
			if on_complete then on_complete() end
		end
		if G.TIMELINE and G.TIMELINE.enqueue then
			Scheduler.add{
				mode = "delayed",
				delay = #letters * stagger + finish_delay,
				blocking = true,
				func = function()
					finish()
					return true
				end,
			}
		else
			finish()
		end
	end
end
