--[[
	word_game/model/profile_stats.lua - card discovery tallies and profile progress.
]]
local Scheduler = require "app.effects.scheduler"

function set_profile_progress()
	local empty = { tally = 0, of = 0 }
	G.PROGRESS = {
		joker_stickers = { tally = 0, of = 0 },
		deck_stakes = { tally = 0, of = 0 },
		challenges = { tally = 0, of = 0 },
	}
	G.PROFILES[G.SETTINGS.profile].progress.joker_stickers = deep_clone(empty)
	G.PROFILES[G.SETTINGS.profile].progress.deck_stakes = deep_clone(empty)
	G.PROFILES[G.SETTINGS.profile].progress.challenges = deep_clone(empty)
end

function discover_card(card)
	if G.GAME.seeded or G.GAME.challenge then return end
	card = card or {}
	if card.discovered or card.wip then return end
	card.discovered = true
	sync_discover_counts()
	Scheduler.add{
		func = function()
			G:queue_progress_write()
			return true
		end,
	}
end

function sync_discover_counts()
	G.DISCOVER_TALLIES = G.DISCOVER_TALLIES or {
		companions = { tally = 0, of = 0 },
		usables = { tally = 0, of = 0 },
		orbits = { tally = 0, of = 0 },
		phantoms = { tally = 0, of = 0 },
		perks = { tally = 0, of = 0 },
		editions = { tally = 0, of = 0 },
		backs = { tally = 0, of = 0 },
		total = { tally = 0, of = 0 },
	}
	for _, v in pairs(G.DISCOVER_TALLIES) do
		v.tally = 0
		v.of = 0
	end

	for _, v in pairs(G.P_CENTERS) do
		if not v.omit then
			if v.set and ((v.set == 'Companion') or v.usable or (v.set == 'Finish') or (v.set == 'Perk') or (v.set == 'Back')) then
				G.DISCOVER_TALLIES.total.of = G.DISCOVER_TALLIES.total.of + 1
				if v.discovered then
					G.DISCOVER_TALLIES.total.tally = G.DISCOVER_TALLIES.total.tally + 1
				end
			end
			if v.set and v.set == 'Companion' then
				G.DISCOVER_TALLIES.companions.of = G.DISCOVER_TALLIES.companions.of + 1
				if v.discovered then
					G.DISCOVER_TALLIES.companions.tally = G.DISCOVER_TALLIES.companions.tally + 1
				end
			end
			if v.set and v.set == 'Back' then
				G.DISCOVER_TALLIES.backs.of = G.DISCOVER_TALLIES.backs.of + 1
				if v.unlocked then
					G.DISCOVER_TALLIES.backs.tally = G.DISCOVER_TALLIES.backs.tally + 1
				end
			end
			if v.set and v.usable then
				G.DISCOVER_TALLIES.usables.of = G.DISCOVER_TALLIES.usables.of + 1
				if v.discovered then
					G.DISCOVER_TALLIES.usables.tally = G.DISCOVER_TALLIES.usables.tally + 1
				end
				if v.set == 'Orbit' then
					G.DISCOVER_TALLIES.orbits.of = G.DISCOVER_TALLIES.orbits.of + 1
					if v.discovered then
						G.DISCOVER_TALLIES.orbits.tally = G.DISCOVER_TALLIES.orbits.tally + 1
					end
				elseif v.set == 'Phantom' then
					G.DISCOVER_TALLIES.phantoms.of = G.DISCOVER_TALLIES.phantoms.of + 1
					if v.discovered then
						G.DISCOVER_TALLIES.phantoms.tally = G.DISCOVER_TALLIES.phantoms.tally + 1
					end
				end
			end
			if v.set and v.set == 'Perk' then
				G.DISCOVER_TALLIES.perks.of = G.DISCOVER_TALLIES.perks.of + 1
				if v.discovered then
					G.DISCOVER_TALLIES.perks.tally = G.DISCOVER_TALLIES.perks.tally + 1
				end
			end
			if v.set and v.set == 'Finish' then
				G.DISCOVER_TALLIES.editions.of = G.DISCOVER_TALLIES.editions.of + 1
				if v.discovered then
					G.DISCOVER_TALLIES.editions.tally = G.DISCOVER_TALLIES.editions.tally + 1
				end
			end
		end
	end
	G.PROFILES[G.SETTINGS.profile].high_scores.collection.amt = G.DISCOVER_TALLIES.total.tally
	G.PROFILES[G.SETTINGS.profile].high_scores.collection.tot = G.DISCOVER_TALLIES.total.of
	G.PROFILES[G.SETTINGS.profile].progress.discovered = deep_clone(G.DISCOVER_TALLIES.total)
end
