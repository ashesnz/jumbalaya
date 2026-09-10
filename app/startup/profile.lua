--[[
	app/startup/profile.lua - Game hooks for profile load and language setup.

	Domain logic lives in word_game/model/meta/profile.lua (WORD_GAME.Meta.Profile).
]]

local Profile = require("word_game.model.meta.profile")

function Game:load_profile(_profile)
	Profile.load(_profile)
end

function Game:set_language()
	Profile.set_language(self)
end
