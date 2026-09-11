--[[
	app/callbacks/registry.lua - Central registry of UIBox callback modules.

	App callbacks (loaded via app.callbacks.settings before WORD_GAME):
	  app.callbacks.ui_controls  - buttons, toggles, sliders, option cycles
	  app.callbacks.window       - display, resolution, vsync, graphics
	  app.callbacks.overlays     - overlay menus, tabs, collection screens
	  app.callbacks.run_lifecycle - start_run, go_to_menu, wipe transitions
	  app.effects                - shared runtime effects (loaded separately in game_boot)

	Word game callbacks (registration only — logic on controllers):
	  word_game.ui.controllers.gameplay       - shuffle, play, recall, jumble_next
	  word_game.ui.controllers.trade          - trade_*
	  word_game.ui.controllers.sidebar        - sidebar HUD actions
	  word_game.ui.callbacks.tutorial         - first_play_tutorial_next

	App controllers (Phase 4b — registration in app/callbacks/*):
	  app.controllers.run_lifecycle, settings, overlays, ui_controls

	Instance-bound sidebar callbacks (registration via sidebar:install()):
	  word_game.ui.sidebar.funcs            - ensure/rebuild/end_run/classic_stage_next
]]

local word_game_callbacks = {
	"word_game.ui.callbacks.table_controls",
	"word_game.ui.callbacks.trade",
	"word_game.ui.callbacks.tutorial",
}

for _, name in ipairs(word_game_callbacks) do
	require(name)

end
