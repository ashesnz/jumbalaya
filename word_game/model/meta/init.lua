--[[ word_game/model/meta - Profile persistence and card discovery side effects ]]

local discover = require("word_game.model.meta.profile_stats")

return {
	Profile = require("word_game.model.meta.profile"),
	discover_card = discover.discover_card,
}
