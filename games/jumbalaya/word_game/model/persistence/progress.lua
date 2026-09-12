--[[
	word_game/model/persistence/progress.lua - Card discovery unlock and queue_progress_write profile UDA payload

	Core: none
	Store: live_game().ARGS.progress_payload, WRITE_FLAGS
	Presentation: none
]]

local live_game = require("word_game.model.live_game")

local Scheduler = require "jumbalaya-engine.effects.timeline_scheduler"
local game_access = require("word_game.model.game_access")

local M = {}

function M.discover_card(card)
	if not card or card.discovered or card.wip then return end
	local game = game_access.get()
	if game and (game.seeded or game.challenge) then return end
	card.discovered = true
	Scheduler.add{
		func = function()
			live_game():queue_progress_write()
			return true
		end,
	}
end

-- Card model loads before WORD_GAME; keep global for card_ability.lua.
discover_card = M.discover_card

function M.queue_progress_write()
	live_game().ARGS.progress_payload = live_game().ARGS.progress_payload or {}
	live_game().ARGS.progress_payload.UDA = clear_table(live_game().ARGS.progress_payload.UDA)
	live_game().ARGS.progress_payload.SETTINGS = live_game().SETTINGS
	live_game().ARGS.progress_payload.PROFILE = live_game().PROFILES[live_game().SETTINGS.profile]

	local centers = live_game().LETTERS and live_game().LETTERS.centers
	if not centers then return end
	for key, definition in pairs(centers) do
		live_game().ARGS.progress_payload.UDA[key] =
			(definition.unlocked and 'u' or '')..
			(definition.discovered and 'd' or '')..
			(definition.alerted and 'a' or '')
	end

	live_game().WRITE_FLAGS = live_game().WRITE_FLAGS or {}
	live_game().WRITE_FLAGS.progress = true
	live_game().WRITE_FLAGS.update_queued = true
end

return M
