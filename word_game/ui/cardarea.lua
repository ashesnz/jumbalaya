--[[
	word_game/ui/cardarea.lua - CardArea facade.

	The implementation lives in focused modules under word_game/ui/cardarea/.
	This module retains the original require path and CardArea global class.
]]

package.loaded["word_game.ui.cardarea.init"] = nil
package.loaded["word_game.ui.cardarea.hand"] = nil
package.loaded["word_game.ui.cardarea.deck"] = nil
package.loaded["word_game.ui.cardarea.placement"] = nil

CardArea = require("word_game.ui.cardarea.init")

return CardArea
