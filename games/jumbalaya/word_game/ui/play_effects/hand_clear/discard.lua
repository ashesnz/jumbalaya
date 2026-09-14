--[[ word_game/ui/play_effects/hand_clear/discard.lua - Animate leftover hand cards away ]]

local GameRT = require("word_game.ui.util.game_runtime")
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
local CardMotion = require("word_game.ui.effects.card_motion")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.discard_remaining_hand()
	if not runtime().dealt_letters then return 0 end
	local n = #(runtime().dealt_letters.cards or {})
	if runtime().TIMELINE and runtime().TIMELINE.enqueue then
		for i = 1, n do
			Scheduler.add{
				mode = "delayed",
				delay = 0.07,
				func = function()
					local card = runtime().dealt_letters and runtime().dealt_letters.cards and runtime().dealt_letters.cards[1]
					if card then
						CardMotion.move{
							from = runtime().dealt_letters,
							to = runtime().recycle_stash,
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
