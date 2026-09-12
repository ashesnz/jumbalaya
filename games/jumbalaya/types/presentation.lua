--[[
	types/presentation.lua - Presentation bus contract (analyzer-only).

	Model→UI one-way notifications registered at boot in
	word_game/ui/presentation/install.lua. Unlike UIBox callbacks (see types/funcs.lua),
	there is no enumerated event catalog — event names are plain strings.
]]

---@meta

--- Event name. Not validated at runtime; one handler per name.
---@alias PresentationEvent string

--- Model→UI notification bus (`word_game/model/presentation.lua`).
---
--- Contract:
--- - **1:1 hash** — at most one handler per event name.
--- - **`on()` overwrites** — registering again replaces the previous handler.
--- - **Partial catalog** — common events are listed below; discover full handlers in
---   `word_game/ui/presentation/install.lua` and model `Presentation.emit` call sites.
---
--- Documented events:
--- - `card_motion_move` (opts) — animated pile transfer; handler: CardMotion.move
--- - `hand_shuffle_sync` — refresh play/shuffle table controls after hand layout changes
--- - `try_snap` effects — board snap returns `{ hand_shuffle_sync = true }`; UI emits this event
--- - **`emit` is notify, not query** — model reads domain state via game_access and `WORD_GAME.*`
---   facades; do not emit to fetch values from UI.
--- - **Boot wiring** — `Presentation.clear()` then `install()` in game boot; tests use
---   `mock_env.install_presentation()`.
---
---@class Presentation
---@field on fun(event: PresentationEvent, fn: fun(...: any))
---@field emit fun(event: PresentationEvent, ...: any): any
---@field clear fun()
