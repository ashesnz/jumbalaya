--[[
	types/presentation.lua - Presentation bus contract (analyzer-only).

	Model→UI one-way notifications registered at boot in
	word_game/ui/presentation/install.lua. Unlike G.FUNCS (see types/g_funcs.lua),
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
--- - **No catalog** — names are conventions, not a closed set; discover handlers in
---   `word_game/ui/presentation/install.lua` and model `Presentation.emit` call sites.
--- - **`emit` is notify, not query** — model reads domain state via `G.GAME` and `WORD_GAME.*`
---   facades; do not emit to fetch values from UI.
--- - **Boot wiring** — `Presentation.clear()` then `install()` in game boot; tests use
---   `mock_env.install_presentation()`.
---
---@class Presentation
---@field on fun(event: PresentationEvent, fn: fun(...: any))
---@field emit fun(event: PresentationEvent, ...: any): any
---@field clear fun()
