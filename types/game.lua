--[[
	types/game.lua - Live run state on Game.GAME (analyzer-only).

	Runtime bus (live state on the Game shell via bridge/runtime.lua):
	- **Game.GAME** — authoritative run snapshot; domain modules read/write through their owner.
	- **UIBox callbacks** — string handlers via bridge/funcs_registry.lua (catalog: types/funcs.lua).
	- **Presentation** — model→UI notify (contract: types/presentation.lua).

	Cross-package API:
	- **WORD_GAME** / **WORD_GAME_UI** facades are the supported entry points for app/, tests/,
	  and devtools. Prefer facade methods over new top-level Game.GAME keys.
	- Do not guard UI with `WORD_GAME and WORD_GAME_UI.X` — after boot `WORD_GAME` is always
	  set; test the export: `if WORD_GAME_UI.X then …`. Use `WORD_GAME.Jumble` etc. for domain.

	Letter registry and run inventory:
	- **LETTERS** — face/center definitions (`faces`, `centers`, `center_pools`, `locked`).
	- **letter_inventory** — live letter cards for the run; **letter_card_id** — next instance id.
	- Set progress: **Game.GAME.word_round.set** only.

	TABLE_BOARD CardArea instances (prefer `WORD_GAME.Deck` / `Board` accessors in new code):
	- **dealt_letters** — player's dealt row (was hand)
	- **draw_pile** — draw stack (was deck)
	- **recycle_stash** — recycle / fly-off stash (was discard)
	- **pattern_row** — pattern row controller; `.area` is the placement CardArea

	Adding fields — **do not grow the Game shell ad hoc**:
	- **Run state** → Game.GAME only. New feature needs a facade method + owned field on
	  `GameRunState` in types/store.lua (declare owner there) or it does not ship.
	- **Live scene nodes** (CardArea, UIBox, overlays) may stay on the Game shell as engine/runtime
	  wiring; prefer `WORD_GAME.Deck` / `Board` accessors over new top-level names.
	- **Letter definitions** → LETTERS via `word_game/model/cards/registry.lua`, not
	  ad-hoc globals. `app/core/` must not reference jumble, letters, or card faces.
	- After `GameRunState` is fully closed, re-enable `inject-field` in `.emmyrc.json`.
]]

---@meta

---@class Transform
---@field x number
---@field y number
---@field w number
---@field h number
---@field r number
---@field scale number

---@class GameTimers
---@field TOTAL number
---@field REAL number
---@field UPTIME number
---@field BACKGROUND number

---@class CardCenter
---@field name string
---@field effect any
---@field set string
---@field config table
---@field order any
---@field cost number
---@field label string|nil
---@field discovered boolean|nil
---@field eternal_compat boolean|nil

---@class CardAbility
---@field name string
---@field effect any
---@field set string
---@field extra table|nil
---@field extra_value number
---@field bonus number
---@field h_size number
---@field d_size number
---@field couponed any
---@field [string] any

--- Run snapshot schema (GameRunState, WordRound, RunState, …): types/store.lua

---@class WordGameTableDeck
---@field uses_table_draw fun(): boolean
---@field draw fun(area: CardArea)
---@field show_info fun()

---@class WordGameCardInspect
---@field is fun(card: Card): boolean
---@field can_inspect fun(card: SceneNode): boolean
---@field begin_hold fun(card: SceneNode)

---@class WordGameTableControls
---@field sync fun()
---@field sync_position fun()
---@field stabilize_table_board fun()
---@field shuffle_hand fun()
---@field placement_has_cards fun(): boolean
---@field destroy fun()|nil

---@class WordGamePlay
---@field on_hand_cleared fun(opts: table|nil)|nil
---@field continue_after_dealer fun()|nil
---@field resolve_after_clear fun(opts: table|nil): string
---@field jumble_next fun(opts: table|nil)|nil

---@class WordGame
---@field Deck table|nil
---@field Jumble table|nil
---@field Play WordGamePlay|nil
---@field TableControls WordGameTableControls|nil
---@field BonusStack table|nil
---@field BonusStackUI table|nil
---@field TableDeck WordGameTableDeck|nil
---@field TableInput { refresh_card_input: fun() }|nil
---@field CardInspect WordGameCardInspect|nil
---@field Layout { sidebar_frac: fun(): number, sidebar_width: fun(): number, inner_width: fun(): number, update_all: fun(), request_refresh: fun(), refresh_placement_layout: fun()|nil }|nil
---@field TableBoard { update: fun(game: Game, dt: number), draw_board: fun(game: Game), is_active: fun(): boolean }|nil
---@field Sidebar table|nil
---@field TradeUI table|nil
---@field ScoreBanner table|nil
---@field TimelineTimer table|nil
---@field TokenReward table|nil
---@field CardFlyOff table|nil
---@field InputLock table|nil

---@class GameInstanceTables
---@field NODE SceneNode[]
---@field MOVEABLE EaseNode[]
---@field SPRITE Sprite[]
---@field UIBOX UIPanel[]
---@field POPUP any[]
---@field CARD Card[]
---@field CARDAREA CardArea[]
---@field ALERT any[]

---@class GameThreadManager
---@field thread love.Thread
---@field channel love.Channel
---@field load_channel love.Channel|nil
---@field out_channel love.Channel|nil
---@field in_channel love.Channel|nil

---@class GameAtlasSpec
---@field name string
---@field path string
---@field px number
---@field py number
---@field frames number|nil
---@field cols number|nil
---@field rows number|nil
---@field type string|nil

---@class GameFontSpec
---@field file string
---@field render_scale number
---@field TEXT_HEIGHT_SCALE number
---@field TEXT_OFFSET {x: number, y: number}
---@field FONTSCALE number
---@field squish number
---@field DESCSCALE number
---@field FONT love.Font

---@class GameLanguage
---@field font GameFontSpec
---@field label string
---@field key string
---@field button string|nil
---@field warning string[]|nil
---@field beta boolean|nil
---@field omit boolean|nil

---@class (partial) Game : Class
---@field VERSION string
---@field STATE integer
---@field STAGE integer
---@field STATES table<string, integer>
---@field STAGES table<string, integer>
---@field STATE_COMPLETE boolean
---@field SETTINGS table
---@field F_RUMBLE any
---@field F_ENGLISH_ONLY boolean
---@field F_DISP_USERNAME any
---@field F_DISCORD boolean
---@field F_PS4_PLAYSTATION_GLYPHS boolean
---@field F_SWAP_AB_PIPS boolean
---@field focused_profile number
---@field save_settings fun(self: Game)
---@field C table
---@field UIT table
---@field ARGS table
---@field I GameInstanceTables
---@field TIMERS GameTimers
---@field FRAMES { DRAW: number, MOVE: number }
---@field GAME GameRunState Live run snapshot — field owners in types/store.lua
---@field ROOM SceneNode
---@field ROOM_ATTACH EaseNode
---@field dealt_letters CardArea|nil Player's dealt letter row
---@field draw_pile CardArea|nil Draw pile (sidebar stack)
---@field recycle_stash CardArea|nil Played / fly-off recycle stash (off-screen)
---@field pattern_row PlacementTable|nil Pattern row controller (`.area` is the CardArea)
---@field hand_action_bar UIPanel|nil
---@field table_shuffle_bar UIPanel|nil
---@field hand_play_button UIPanel|nil
---@field table_shuffle_button UIPanel|nil
---@field PLAY_WORD_UI UIPanel|nil
---@field SIDEBAR_HUD UIPanel|nil
---@field TIMELINE table|nil
---@field OVERLAY_MENU UIPanel|nil
---@field RUN { active: boolean }|nil
---@field view_deck CardArea[]|nil
---@field VIEWING_DECK any
---@field deck_preview any
---@field real_dt number
---@field HIGHLIGHT_H number
---@field E_MANAGER Scheduler
---@field CONTROLLER InputController
---@field CURSOR Sprite
---@field MOVEABLES EaseNode[]
---@field DRAW_HASH SceneNode[]
---@field debug_panel DebugPanel|nil
---@field VIBRATION number
---@class LettersRegistry
---@field faces table<string, table>
---@field centers table<string, CardCenter>
---@field center_pools table<string, CardCenter[]>
---@field locked CardCenter[]
---@field LETTERS LettersRegistry|nil
---@field letter_inventory Card[]|nil
---@field letter_card_id number|nil
---@field CARD_W number
---@field CARD_H number
---@field TILESIZE number
---@field TILESCALE number
---@field TILE_W number
---@field TILE_H number
---@field CANV_SCALE number
---@field SHADERS table<string, love.Shader>
---@field ASSET_ATLAS table
---@field ANIMATION_ATLAS table
---@field animation_atli GameAtlasSpec[]
---@field asset_atli GameAtlasSpec[]
---@field asset_images GameAtlasSpec[]
---@field ANIMATIONS table
---@field SPEEDFACTOR number
---@field shared_debuff Sprite
---@field ROOM_PADDING_H number
---@field ROOM_PADDING_W number
---@field WINDOWTRANS table
---@field window_prev table
---@field LANGUAGES table<string, GameLanguage>
---@field FONTS GameFontSpec[]
---@field BRUTE_OVERLAY table|nil
---@field HAND_CARD_SPACING number|nil
---@field TABLE_HAND_SIZE integer
---@field OVERLAY_MENU UIPanel|nil
---@field SHOW_SIDE_PANEL boolean
---@field check any
---@field LOADING any
---@field SPLASH_VOL number
---@field E_SWITCH_POINT number
---@field PROGRESS any
---@field DISCOVER_TALLIES any
---@field FILE_HANDLER any
---@field SAVED_GAME any
---@field action any
---@field culled_table any
---@field ROOM_ORIG any
---@field screenwipecard Card|nil
---@field muted boolean
---@field F_MUTE boolean
---@field F_ENABLE_PERF_OVERLAY boolean
---@field F_SOUND_THREAD boolean
---@field F_STREAMER_EVENT boolean
---@field F_VERBOSE boolean
---@field FPS_CAP number
---@field SEED number
---@field keybind_mapping any
---@field button_mapping table
---@field F_NO_ERROR_HAND boolean
---@field F_CRASH_REPORTS boolean
---@field buttons UIPanel|nil
---@field HUD UIPanel|nil
---@field CANVAS love.Canvas|nil
---@field update fun(self: Game, dt: number)
---@field draw fun(self: Game)
---@field STEAM LuaSteam|nil
---@field SOUND_MANAGER GameThreadManager|nil
---@field SAVE_MANAGER GameThreadManager
---@field PITCH_MOD number
---@field LANG GameLanguage
---@field localization table
---@field selected_back any
---@field PROFILES table
---@field start_up fun(self: Game)
---@field load_profile fun(self: Game, _profile: number)
---@field set_language fun(self: Game)
---@field set_render_settings fun(self: Game)
---@field init_window fun(self: Game, reset: boolean|nil)
---@field init_item_prototypes fun(self: Game)
---@field start_run fun(self: Game, args: table|nil)
---@field start_gameplay_board fun(self: Game)
---@field [string] any

---@type Game
G = {}

---@type WordGame
WORD_GAME = {}
