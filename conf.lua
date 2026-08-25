--[[
	conf.lua - LÖVE reads this before creating the window.
	Keep window/title defaults in word_game/config/runtime.lua so they stay in one place.
]]

function love.conf(t)
	require("word_game.config.runtime").love_conf(t)
end
