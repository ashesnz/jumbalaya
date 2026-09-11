--[[
	conf.lua - LÖVE reads this before creating the window.
	Keep window/title defaults in word_game/config/boot/runtime.lua.
]]

package.path = "../../packages/?.lua;../../packages/?/init.lua;./?.lua;./?/init.lua;" .. package.path

function love.conf(t)
	require("word_game.config.boot.runtime").love_conf(t)
end
