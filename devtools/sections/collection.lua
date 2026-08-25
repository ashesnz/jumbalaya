--[[ devtools/sections/collection.lua - Open The Card Marketplace from the debug panel. ]]

local layout = require "devtools.layout"

return {
	id = "collection",
	order = 45,

	register = function(panel)
		panel:action("show_trade", function(_ctx)
			if WORD_GAME and WORD_GAME.TradeUI then
				WORD_GAME.TradeUI.open()
			end
		end)
		panel:action("show_perk_market", function(_ctx)
			if WORD_GAME and WORD_GAME.PerkMarketplace then
				WORD_GAME.PerkMarketplace.show()
			end
		end)
	end,

	build = function(_panel)
		return layout.section("Marketplace", layout.button_columns({
			{ label = "Card Marketplace", action = "show_trade" },
			{ label = "Perk Marketplace", action = "show_perk_market" },
		}))
	end,
}
