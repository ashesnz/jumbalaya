--[[
	types/g_funcs.lua - Catalog of G.FUNCS string names (analyzer-only).

	UI definitions bind these by string. Implementations live in app/callbacks
	and word_game/ui; model code must not call G.FUNCS.
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
---| "set_button_pip"
---| "pulse_node"
---| "setup_run"
---| "notify_then_start_run"
---| "notify_then_setup_run"
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
---| "jumble_next"
---| "trade_pick"
---| "trade_skip_add"
---| "trade_skip_remove"
---| "trade_skip"
---| "play_placement_word"
---| "ensure_table_board_sidebar"
---| "rebuild_table_board_sidebar"
---| "end_run_from_sidebar"
---| "classic_stage_next"
---| "first_play_tutorial_next"

---@class GameFuncs
---@field [GameFuncName] fun(...: any)
---@field [string] fun(...: any)
