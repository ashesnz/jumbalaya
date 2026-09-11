--[[
	types/g_funcs.lua - G.FUNCS string catalog (analyzer-only).

	UIBox binds these names on buttons and widgets. Implementations are
	**registration only**:

	  G.FUNCS.play_placement_word = WORD_GAME_UI.TableControls.play

	Logic lives on WORD_GAME_UI / app callback modules. Model code must not
	call G.FUNCS (use Presentation or facades).

	Runtime bus: G.FUNCS (this catalog), G.GAME (types/game.lua),
	Presentation (types/presentation.lua).
]]

---@meta

---@alias GameFuncName
---| "open_options"
---| "open_settings"
---| "language_selection"
---| "profile_select"
---| "quit"
---| "warn_lang"
---| "change_lang"
---| "copy_run_seed"
---| "show_infotip"
---| "key_button"
---| "text_input"
---| "paste_run_seed"
---| "focus_text_field"
---| "text_field_key"
---| "change_vsync"
---| "change_screen_resolution"
---| "change_screenmode"
---| "change_display"
---| "change_window_cycle_UI"
---| "change_gamespeed"
---| "change_shadows"
---| "change_pixel_smoothing"
---| "can_apply_window_changes"
---| "apply_window_changes"
---| "cycle_option"
---| "drag_slider"
---| "slider_step"
---| "flip_switch"
---| "set_button_pip"
---| "pulse_node"
---| "notify_then_start_run"
---| "begin_run"
---| "begin_classic_run"
---| "begin_time_run"
---| "return_to_menu"
---| "switch_tab"
---| "show_overlay"
---| "close_overlay"
---| "can_resume_run"
---| "can_load_profile"
---| "load_profile"
---| "can_delete_profile"
---| "delete_profile"
---| "wipe_in"
---| "wipe_out"
---| "shuffle_hand"
---| "return_placement_cards"
---| "play_placement_word"
---| "jumble_next"
---| "trade_pick"
---| "trade_skip_add"
---| "trade_skip_remove"
---| "trade_skip"
---| "ensure_table_board_sidebar"
---| "rebuild_table_board_sidebar"
---| "end_run_from_sidebar"
---| "classic_stage_next"
---| "first_play_tutorial_next"

--- UIBox input dispatch on G. String keys only — see GameFuncName.
---@class GameFuncs
---@field [GameFuncName] fun(...: any)
---@field [string] fun(...: any)
