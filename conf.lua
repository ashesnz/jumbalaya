--[[ Root shim — prefer: love games/jumbalaya ]]

package.path = "./packages/?.lua;./packages/?/init.lua;./games/jumbalaya/?.lua;./games/jumbalaya/?/init.lua;" .. package.path

function love.conf(t)
	require("word_game.config.boot.runtime").love_conf(t)
end
