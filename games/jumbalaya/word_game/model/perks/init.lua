--[[ word_game/model/perks/init.lua - Perk model package (registry, hand timer). ]]

return {
	Registry = require("word_game.model.perks.registry"),
	Effects = require("word_game.model.perks.effects"),
	VoucherDiscard = require("word_game.model.perks.voucher_discard"),
}
