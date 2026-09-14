--[[
	app/bootstrap/kind_globals.lua - Game Kind classes → _G (single boot hook).

	Engine classes install via jumbalaya-engine.globals. Gameplay classes install here.
]]

local M = {}

function M.install_game()
	_G.Game = require("word_game.model.game")
end

function M.install_card_types()
	_G.Card = require("word_game.model.cards.card")
	require("word_game.ui.cards.bind").install()
	_G.CardPile = require("word_game.ui.cardarea.init")
end

function M.install_ui_types()
	_G.TitleLogo = require("word_game.ui.menu.title_logo")
	_G.PerkVoucherSprite = require("word_game.ui.perks.shared.voucher_sprite")
end

function M.install()
	M.install_game()
	M.install_card_types()
	M.install_ui_types()
end

return M
