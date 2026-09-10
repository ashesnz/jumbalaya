--[[
	types/emmyrc.lua - EmmyLua analyzer policy (analyzer-only).

	Config file: `.emmyrc.json` at repo root.

	While `G` remains a partial god object, these diagnostics stay disabled in
	`.emmyrc.json` → `diagnostics.disable`:
	- inject-field
	- missing-fields
	- access-invisible

	Re-enable individually after tightening `types/game.lua` or module annotations.
	CI runs `emmylua_check . --severity error`; local refactors use `--severity warn`.
]]

---@meta
