--[[
	word_game/model/profile_stats.lua - minimal card discovery hooks.

	Balatro-era collection tallies were removed; these stubs keep card
	discovery persistence without profile/collection UI.
]]
local Scheduler = require "app.effects.scheduler"

function set_profile_progress()
end

function discover_card(card)
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

function sync_discover_counts()
end
