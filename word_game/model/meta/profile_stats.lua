--[[ word_game/model/meta/profile_stats.lua - Card discovery persistence ]]

local Scheduler = require "app.effects.timeline_scheduler"

local M = {}

function M.discover_card(card)
	if not card or card.discovered or card.wip then return end
	if G.GAME and (G.GAME.seeded or G.GAME.challenge) then return end
	card.discovered = true
	Scheduler.add{
		func = function()
			G:queue_progress_write()
			return true
		end,
	}
end

-- Card model loads before WORD_GAME; keep global for card_ability.lua.
discover_card = M.discover_card

return M
