--[[ word_game/model/persistence/progress.lua - Profile progress payload and card discovery ]]

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

function M.queue_progress_write()
	G.ARGS.progress_payload = G.ARGS.progress_payload or {}
	G.ARGS.progress_payload.UDA = clear_table(G.ARGS.progress_payload.UDA)
	G.ARGS.progress_payload.SETTINGS = G.SETTINGS
	G.ARGS.progress_payload.PROFILE = G.PROFILES[G.SETTINGS.profile]

	local centers = G.LETTERS and G.LETTERS.centers
	if not centers then return end
	for key, definition in pairs(centers) do
		G.ARGS.progress_payload.UDA[key] =
			(definition.unlocked and 'u' or '')..
			(definition.discovered and 'd' or '')..
			(definition.alerted and 'a' or '')
	end

	G.WRITE_FLAGS = G.WRITE_FLAGS or {}
	G.WRITE_FLAGS.progress = true
	G.WRITE_FLAGS.update_queued = true
end

return M
