--[[ Root shim — prefer: love games/jumbalaya/tests ]]

package.path = "./packages/?.lua;./packages/?/init.lua;./games/jumbalaya/?.lua;./games/jumbalaya/?/init.lua;" .. package.path

function love.conf(t)
	t.window = nil
	t.modules.window = false
	t.modules.graphics = false
	t.modules.audio = false
	t.modules.physics = false
	t.console = true
end
