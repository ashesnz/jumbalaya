--[[
	types/presentation_events.lua - Presentation bus event catalog (analyzer-only).

	Handlers register at boot in word_game/ui/presentation/handlers/ (via install.lua).
	Model emits via word_game/model/presentation.lua; UI may emit for play resolution
	or board snap side effects (see types/presentation.lua).

	Static audit: tests/helpers/presentation_catalog_audit.lua
]]

---@meta

---@alias PresentationEventName
---| "PLAY_RESOLVED"
---| "bonus_card_return"
---| "bonus_stack_on_hand_start"
---| "boss_puzzle_revealed"
---| "boss_word_begin"
---| "card_motion_move"
---| "hand_shuffle_sync"
---| "hand_shuffle_sync_position"
---| "hand_started"
---| "jumble_hud_refresh"
---| "layout_refresh"
---| "layout_refresh_placement"
---| "match_ended"
---| "puzzle_applied"
---| "round_restore_from_save"
---| "run_backgrounds"
---| "run_board_ready"
---| "score_banner_hide_points"
---| "score_banner_jumble_hand_start"
---| "score_banner_reset"
---| "score_banner_reset_jumble"
---| "score_banner_set_mode"
---| "score_banner_snap"
---| "score_banner_sync_preview"
---| "sidebar_clear_hand"
---| "sidebar_ensure"
---| "sidebar_refresh"
---| "sidebar_sync_visibility"
---| "stage_backgrounds"
---| "stage_label_force_sync"
---| "stage_label_sync"
---| "table_deck_reset"
---| "timeline_apply_seconds"
---| "timeline_reset"
---| "timeline_reset_puzzle_smoke"
---| "timeline_sync_from_model"
---| "timeline_sync_progress"
---| "voucher_discard_recorded"
---| "voucher_discard_ui_reset"
---| "voucher_discard_ui_sync"

--[[
	Event reference (payload → handler module → primary emitter):

	PLAY_RESOLVED (result) — score_banner — ui/play_effects/resolution.lua
	bonus_card_return (card) → bool — play — model/jumble/bonus_return.lua
	bonus_stack_on_hand_start (set, hand_index) — play — composed from hand_started
	boss_puzzle_revealed () — play — model/jumble/hand.lua
	boss_word_begin (wr, on_complete) → bool — play — model/jumble/hand.lua
	card_motion_move (opts) → bool — table — model/card_motion_request.lua
	hand_shuffle_sync () — sidebar — model/cards/deck/jumble_discard.lua, ui/cards/ui.lua
	hand_shuffle_sync_position () — sidebar — composed from boss_puzzle_revealed
	hand_started (set, hand_index) — play — model/round/init.lua
	jumble_hud_refresh () — score_banner — model/jumble/hand.lua; re-emitted from PLAY_RESOLVED
	layout_refresh () — layout — handler only (prefer LayoutRequest.refresh in model)
	layout_refresh_placement () — layout — composed from boss_puzzle_revealed
	match_ended (won) — play — model/game/loop.lua
	puzzle_applied () — play — model/jumble/hand.lua
	round_restore_from_save (wr) — play — model/round/init.lua
	run_backgrounds () — layout — model/game/run.lua
	run_board_ready () — play — model/game/run.lua
	score_banner_hide_points () — score_banner — composed from boss_puzzle_revealed
	score_banner_jumble_hand_start () — score_banner — model/jumble/hand.lua
	score_banner_reset (target) — score_banner — composed from hand_started, round_restore_from_save
	score_banner_reset_jumble () — score_banner — composed from puzzle_applied
	score_banner_set_mode (mode, label) — score_banner — composed from boss_puzzle_revealed
	score_banner_snap () — score_banner — composed from round_restore_from_save
	score_banner_sync_preview (enabled) — score_banner — model/jumble/placement_word.lua
	sidebar_clear_hand () — sidebar — composed from hand_started
	sidebar_ensure () — sidebar — model/game/run.lua
	sidebar_refresh () — sidebar — composed from hand_started, round_restore_from_save
	sidebar_sync_visibility () — sidebar — composed from boss_puzzle_revealed
	stage_backgrounds (set, hand_index) — layout — composed from hand_started, round_restore_from_save
	stage_label_force_sync () — score_banner — composed from round_restore_from_save
	stage_label_sync () — score_banner — composed from hand_started
	table_deck_reset () — sidebar — model/cards/deck/identity.lua
	timeline_apply_seconds () — timeline — handler only (no emit site)
	timeline_reset () — timeline — model/round/init.lua; composed from hand_started, round_restore_from_save
	timeline_reset_puzzle_smoke () — timeline — composed from puzzle_applied
	timeline_sync_from_model () — timeline — model/run/timeline.lua
	timeline_sync_progress () — timeline — composed from puzzle_applied
	voucher_discard_recorded (from_left, to_left) — table — model/perks/voucher_discard.lua
	voucher_discard_ui_reset () — table — model/perks/voucher_discard.lua
	voucher_discard_ui_sync () — table — handler only (no emit site)
]]
