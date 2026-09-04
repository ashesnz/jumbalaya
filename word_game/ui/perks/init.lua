--[[
	word_game/ui/perks/ - Perk-adjacent UI (discard bin, timeline fuse, stamp animation).

	Config pool: word_game/config/perks.lua. Gameplay hooks: model/perks/effects.lua.
]]

return {
	DiscardBin = require("word_game.ui.perks.discard_bin"),
	TimelineTimer = require("word_game.ui.perks.timeline_timer"),
	StampGrid = require("word_game.ui.perks.stamp_grid"),
	Voucher = require("word_game.ui.perks.voucher"),
	Stamp = require("word_game.ui.perks.stamp"),
}
