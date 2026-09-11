--[[ tests/conf.lua - Headless test configuration for Love2D ]]

package.path = "../../packages/?.lua;../../packages/?/init.lua;../?.lua;../?/init.lua;./?.lua;./?/init.lua;" .. package.path

function love.conf(t)
	t.window = nil
	t.modules.window = false
	t.modules.graphics = false
	t.modules.audio = false
	t.modules.physics = false
	t.console = true
end
