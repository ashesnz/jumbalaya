--[[
	word_game/ui/perks/ - Perk-adjacent UI (discard bin, timeline fuse, stamp layout).

	Stamp earn animation remains in ui/perk_stamp/; marketplace vouchers use
	ui/perks/voucher.lua. Config pool: word_game/config/perks.lua.
]]

return {
	DiscardBin = require("word_game.ui.perks.discard_bin"),
	TimelineTimer = require("word_game.ui.perks.timeline_timer"),
	StampGrid = require("word_game.ui.perks.stamp_grid"),
	Voucher = require("word_game.ui.perks.voucher"),
}
