--[[
	word_game/ui/util/ - Stateless presentation helpers (no UIBox widgets).

	For reusable on-screen controls (buttons, sliders, odometer), see `ui/widgets/`.
]]

return {
	colour = require("word_game.ui.util.colour"),
	localize = require("word_game.ui.util.localize"),
	number_format = (function()
		require("jumbalaya-engine.util.number_format")
		return number_format
	end)(),
	roll = require("word_game.ui.util.roll"),
}
