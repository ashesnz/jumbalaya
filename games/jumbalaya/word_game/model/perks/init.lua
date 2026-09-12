--[[
	word_game/model/perks/init.lua - Perks package facade (Registry, Effects, VoucherDiscard)

	Core: none
	Store: none
	Presentation: none
]]

return {
	Registry = require("word_game.model.perks.registry"),
	Effects = require("word_game.model.perks.effects"),
	VoucherDiscard = require("word_game.model.perks.voucher_discard"),
}
