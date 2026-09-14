--[[ word_game/ui/play_effects/hand_clear/discard.lua - Animate leftover hand cards away ]]

local game = require("word_game.ui.util.game_runtime").game
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local CardMotion = require("word_game.ui.effects.card_motion")

local M = {}


function M.discard_remaining_hand()
	if not game().dealt_letters then return 0 end
	local n = #(game().dealt_letters.cards or {})
	if game().TIMELINE and game().TIMELINE.enqueue then
		for i = 1, n do
			Scheduler.add{
				mode = "delayed",
				delay = 0.07,
				func = function()
					local card = game().dealt_letters and game().dealt_letters.cards and game().dealt_letters.cards[1]
					if card then
						CardMotion.move{
							from = game().dealt_letters,
							to = game().recycle_stash,
							percent = 50,
							direction = "down",
							stay_flipped = false,
							card = card,
							delay = 0.08,
						}
					end
					return true
				end,
			}
		end
	end
	return n
end

return M
