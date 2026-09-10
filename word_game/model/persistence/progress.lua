--[[ word_game/model/persistence/progress.lua - Profile progress payload (unlock/discovery UDA) ]]

local M = {}

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
