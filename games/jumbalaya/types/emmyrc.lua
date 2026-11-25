--[[
	types/emmyrc.lua - EmmyLua analyzer policy (analyzer-only).

	Config file: `.emmyrc.json` at repo root.

	While the Game shell still carries live scene nodes (CardPile, overlays), these
	diagnostics stay disabled in `.emmyrc.json` → `diagnostics.disable`:
	- inject-field
	- missing-fields
	- access-invisible

	Re-enable `inject-field` first once `GameRunState` in types/store.lua is closed
	(no ad-hoc Game.GAME keys). Then tighten live-node fields on the Game shell or
	move them behind facade-only accessors.

	CI and `/complete-ticket` run `emmylua_check . --severity error`.

	Boot Kind aliases installed by `jumbalaya-engine.globals.install` and
	`app/bootstrap/kind_globals.lua` must be listed in `.emmyrc.json` → `diagnostics.globals`
	if any file uses them without `require` (`Spatial`, `Sprite`, `Node`, `LetterTile`,
	`PerkStampSprite`, …). Add `_G` install and the `diagnostics.globals` entry in the same change.
]]

---@meta
