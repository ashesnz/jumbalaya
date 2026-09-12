--[[
	types/presentation.lua - Presentation bus contract (analyzer-only).

	Model→UI one-way notifications registered at boot in
	word_game/ui/presentation/install.lua. Event names are cataloged in
	types/presentation_events.lua (mirror types/funcs.lua).
]]

---@meta

--- Cataloged event name (`types/presentation_events.lua`).
---@alias PresentationEvent PresentationEventName

--- Model→UI notification bus (`word_game/model/presentation.lua`).
---
--- Contract:
--- - **1:1 hash** — at most one handler per event name.
--- - **`on()` overwrites** — registering again replaces the previous handler.
--- - **Catalog** — `types/presentation_events.lua` lists every handler, payload,
---   and primary emitter; audit via `test_presentation_catalog.lua`.
--- - **`emit` is notify, not query** — model reads domain state via game_access and
---   `WORD_GAME.*` facades; do not emit to fetch values from UI.
--- - **Boot wiring** — `Presentation.clear()` then `install()` in game boot; tests use
---   `mock_env.install_presentation()`.
--- - **Board snap** — `try_snap` returns `{ hand_shuffle_sync = true }`; UI emits
---   `hand_shuffle_sync` (see `word_game/ui/cards/ui.lua`).
---
---@class Presentation
---@field on fun(event: PresentationEvent, fn: fun(...: any))
---@field emit fun(event: PresentationEvent, ...: any): any
---@field clear fun()
