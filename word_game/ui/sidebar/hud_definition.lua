--[[ word_game/ui/sidebar/hud_definition.lua - Sidebar HUD sync helpers (LayoutView retired PR-4) ]]

local Layout = require("word_game.ui.layout")
local hud_layout = require("word_game.ui.sidebar.hud_layout")
local table_discard = require("word_game.ui.perks.discard_bin")
local views_install = require("word_game.ui.views.install")

local M = {}

function M.sync_end_run_row()
	local view = views_install.sidebar_view()
	if view and view.sync_end_run_row then
		view:sync_end_run_row()
		return
	end
	table_discard.sync_discard_pile_area()
	if WORD_GAME_UI.SidebarStageButton and WORD_GAME_UI.SidebarStageButton.sync then
		WORD_GAME_UI.SidebarStageButton.sync()
	end
end

function M.relayout()
	Layout.update_sidebar_attach()
	local view = views_install.sidebar_view()
	if view and view.relayout then
		view:relayout()
	end
	M.sync_end_run_row()
	table_discard.sync_voucher_counter(true)
	Layout.set_screen_positions()
end

function M.hud_layout()
	return hud_layout.compute()
end

if table_discard.bind_hud_definition then
	table_discard.bind_hud_definition(M)
end

return M
