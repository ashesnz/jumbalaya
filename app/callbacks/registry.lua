--[[
	app/callbacks/registry.lua - Central registry of G.FUNCS callback modules.

	App callbacks (loaded via app.callbacks.settings before WORD_GAME):
	  app.callbacks.ui_controls  - buttons, toggles, sliders, option cycles
	  app.callbacks.window       - display, resolution, vsync, graphics
	  app.callbacks.overlays     - overlay menus, tabs, collection screens
	  app.callbacks.run_lifecycle - start_run, go_to_menu, wipe transitions
	  app.effects                - shared runtime effects (loaded separately in game_boot)

	Word game callbacks (loaded eagerly after WORD_GAME facade):
	  word_game.ui.callbacks.hand_shuffle - shuffle_hand, jumble_next
	  word_game.ui.callbacks.trade        - trade_*

	Instance-bound sidebar callbacks are registered via sidebar:install():
	  word_game.ui.callbacks.sidebar      - ensure/rebuild_table_board_sidebar, intro next
]]

local word_game_callbacks = {
	"word_game.ui.callbacks.hand_shuffle",
	"word_game.ui.callbacks.trade",
}

for _, name in ipairs(word_game_callbacks) do
	require(name)
end
