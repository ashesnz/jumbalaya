--[[
	word_game/ui/fx_subscribers.lua - FX modules as store and presentation subscribers (Phase 6).
]]

local Presentation = require("word_game.model.presentation")

local M = {
	_last_jumble_score = nil,
	_installed = false,
}

function M.install(engine, ui)
	if M._installed then return end
	M._installed = true
	ui = ui or rawget(_G, "WORD_GAME_UI") or {}
	local store = engine and engine.store
	if store then
		store:subscribe(function(state)
			if G and G.STAGE ~= G.STAGES.RUN then return end
			local jumble = state.word_round and state.word_round.jumble
			if not jumble then return end
			local score = jumble.total_score or 0
			if M._last_jumble_score ~= score then
				M._last_jumble_score = score
				Presentation.emit("jumble_hud_refresh")
			end
		end)
	end

	if engine and engine.events then
		engine.events:on("PLAY_RESOLVED", function(result)
			if not result or result.kind == "invalid" then return end
			if ui.ScoreBanner and ui.ScoreBanner.sync_points_to_get_preview then
				ui.ScoreBanner.sync_points_to_get_preview(true)
			end
		end)
	end
end

function M.reset()
	M._installed = false
	M._last_jumble_score = nil
end

return M
