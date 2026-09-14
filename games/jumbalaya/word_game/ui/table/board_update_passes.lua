--[[ word_game/ui/table/board_update_passes.lua - TABLE_BOARD per-frame update pass list ]]

local runtime = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local Layout = require("word_game.ui.layout")
local play_effects = require("word_game.ui.play_effects")

local Jumble = facade.jumble()
local Play = facade.jumble_play()

local M = {}

local function refresh_pending_layout()
	if runtime().ARGS and runtime().ARGS.pending_layout then
		runtime().ARGS.pending_layout = false
		Layout.refresh_placement_layout()
	end
end

local function update_devtools()
	if DEVTOOLS and DEVTOOLS.DebugButton then
		DEVTOOLS.DebugButton.sync()
	end
end

local function sync_table_chrome()
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
	if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.sync_visibility then
		WORD_GAME_UI.Sidebar.sync_visibility()
	end
end

local function update_jumble_timer()
	if not Jumble.is_active() then return end
	if not Jumble.update_timer() then return end
	if Play.end_jumble_hand then
		Play.end_jumble_hand()
		if play_effects.present_end_jumble_sidebar then
			play_effects.present_end_jumble_sidebar()
		end
	end
end

local function update_boss_announce(dt)
	if WORD_GAME_UI.BossWordAnnounce and WORD_GAME_UI.BossWordAnnounce.update then
		WORD_GAME_UI.BossWordAnnounce.update(dt)
	end
end

local function update_pattern_row(game, dt, ensure_placement_pattern_overlay)
	if not game.pattern_row then return end
	ensure_placement_pattern_overlay(game.pattern_row)
	game.pattern_row:update(dt)
end

local function update_timeline()
	if WORD_GAME_UI.TimelineTimer and WORD_GAME_UI.TimelineTimer.update then
		WORD_GAME_UI.TimelineTimer.update()
	end
end

function M.run(game, dt, ensure_placement_pattern_overlay)
	refresh_pending_layout()
	update_devtools()
	sync_table_chrome()
	update_jumble_timer()
	update_boss_announce(dt)
	update_pattern_row(game, dt, ensure_placement_pattern_overlay)
	update_timeline()
end

return M
