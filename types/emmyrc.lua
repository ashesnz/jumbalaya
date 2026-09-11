--[[
	types/emmyrc.lua - EmmyLua analyzer policy (analyzer-only).

	Config file: `.emmyrc.json` at repo root.

	While the Game shell still carries live scene nodes (CardArea, overlays), these
	diagnostics stay disabled in `.emmyrc.json` → `diagnostics.disable`:
	- inject-field
	- missing-fields
	- access-invisible

	Re-enable `inject-field` first once `GameRunState` in types/game.lua is closed
	(no ad-hoc Game.GAME keys). Then tighten live-node fields on the Game shell or
	move them behind facade-only accessors.

	CI runs `emmylua_check . --severity error`; local refactors use `--severity warn`.
]]

---@meta
