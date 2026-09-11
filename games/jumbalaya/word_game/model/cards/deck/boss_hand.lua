--[[ word_game/model/cards/deck/boss_hand.lua - Boss-hand deal choreography ]]

local live_game = require("word_game.model.live_game")

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local CardMotion = require "word_game.ui.effects.card_motion"
local LetterPalette = require "word_game.config.visuals.letter_card_palette"
local game_access = require("word_game.model.game_access")

return function(deck_module, context)
	return function(letters, on_complete, opts)
		opts = opts or {}
		local stagger = opts.fast and 0.04 or 0.1
		local finish_delay = opts.fast and 0.06 or 0.2
		if not live_game().dealt_letters or not letters or #letters == 0 then
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
			for pi = #(live_game().letter_inventory or {}), 1, -1 do
				if live_game().letter_inventory[pi] == card then
					table.remove(live_game().letter_inventory, pi)
					break
				end
			end
			j.boss_cards[#j.boss_cards + 1] = card
			live_game().draw_pile:emplace(card)
			if live_game().TIMELINE and live_game().TIMELINE.enqueue then
				Scheduler.add{
					mode = "window",
					delay = (i - 1) * stagger,
					blocking = true,
					func = function()
						CardMotion.move{from = live_game().draw_pile, to = live_game().dealt_letters, percent = 50, direction = "up", stay_flipped = false, card = card, delay = 0.08}
						return true
					end,
				}
			elseif context.fly_from_deck_to_hand then
				context.fly_from_deck_to_hand(card)
			else
				live_game().draw_pile:remove_card(card)
				live_game().dealt_letters:emplace(card)
			end
		end
		local finish = function()
			local wr_finish = game_access.word_round()
			local j_finish = wr_finish and wr_finish.jumble
			if not (j_finish and j_finish.boss_puzzle_hidden)
				and live_game().pattern_row and live_game().pattern_row.apply_screen_position then
				live_game().pattern_row:apply_screen_position()
			end
			if live_game().dealt_letters then
				live_game().dealt_letters:set_ranks()
				live_game().dealt_letters:relayout()
				live_game().dealt_letters:snap_VT()
				live_game().dealt_letters:hard_set_cards()
			end
			if deck_module.commit_pile_hosts then
				deck_module.commit_pile_hosts({ "hand", "draw", "pattern" })
			else
				deck_module.sync_deck_count_display()
			end
			if on_complete then on_complete() end
		end
		if live_game().TIMELINE and live_game().TIMELINE.enqueue then
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
