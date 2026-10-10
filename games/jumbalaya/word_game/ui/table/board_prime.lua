--[[
	word_game/ui/table/board_prime.lua - Synchronous TABLE_BOARD HUD bootstrap.

	Ensures sidebar, table controls, and layout are ready before the first draw
	frame (no deferred pending_layout).
]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

M.REQUIRED_SIDEBAR_ROWS = {
	"row_sidebar_spacer",
	"row_stamp_slot",
	"row_deck",
	"row_deck_count",
	"row_end_run",
}

local function ui()
	return WORD_GAME_UI
end

function M.sidebar_ready(g)
	g = g or game()
	local hud = g.SIDEBAR_HUD
	if not hud or not hud.find_node_by_id then return false end
	for _, row_id in ipairs(M.REQUIRED_SIDEBAR_ROWS) do
		if not hud:find_node_by_id(row_id) then
			return false
		end
	end
	return hud:find_node_by_id("text_deck_count") ~= nil
		and hud:find_node_by_id("end_run_button") ~= nil
end

function M.table_controls_ready(g)
	g = g or game()
	local tc = ui() and ui().TableControls
	if not tc or not tc.buttons_present or not tc.buttons_present() then
		return false
	end
	local play_btn = tc.play_button_uie and tc.play_button_uie()
	local shuffle_btn = tc.shuffle_button_uie and tc.shuffle_button_uie()
	if not play_btn or not shuffle_btn then return false end
	if not play_btn.states or not play_btn.states.visible then return false end
	if not shuffle_btn.states or not shuffle_btn.states.visible then return false end
	return true
end

function M.layout_ready(g)
	g = g or game()
	return not g.pending_layout
end

function M.is_ready(g)
	g = g or game()
	if g.STAGE ~= g.STAGES.RUN or g.STATE ~= g.STATES.TABLE_BOARD then
		return false
	end
	if not g.ROOM_ATTACH or not g.dealt_letters then return false end
	return M.sidebar_ready(g) and M.table_controls_ready(g) and M.layout_ready(g)
end

function M.prime()
	local facade_ui = ui()
	if not facade_ui then return false end

	if facade_ui.Sidebar and facade_ui.Sidebar.ensure then
		facade_ui.Sidebar:ensure()
	end
	if facade_ui.TableControls and facade_ui.TableControls.sync then
		facade_ui.TableControls.sync()
	end
	if facade_ui.Layout and facade_ui.Layout.set_screen_positions then
		facade_ui.Layout.set_screen_positions()
	end

	local g = game()
	if g.SIDEBAR_HUD and g.SIDEBAR_HUD.recalculate then
		g.SIDEBAR_HUD:recalculate()
	end
	if facade_ui.ScoreBanner and facade_ui.ScoreBanner.snap_to_actual then
		facade_ui.ScoreBanner.snap_to_actual()
	end
	if facade_ui.StageLabel and facade_ui.StageLabel.sync then
		facade_ui.StageLabel.sync()
	end
	if facade_ui.TimelineTimer and facade_ui.TimelineTimer.sync_from_model then
		facade_ui.TimelineTimer.sync_from_model()
	end
	if facade_ui.ScoreBanner then
		if facade_ui.ScoreBanner.snap_to_actual then
			facade_ui.ScoreBanner.snap_to_actual()
		end
		if facade_ui.ScoreBanner.sync_points_to_get_preview then
			facade_ui.ScoreBanner.sync_points_to_get_preview(false)
		end
	end
	g.pending_layout = false
	return M.is_ready(g)
end

return M
