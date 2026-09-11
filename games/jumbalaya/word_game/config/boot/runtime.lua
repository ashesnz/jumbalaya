--[[
	config/runtime.lua - Build flags and LÖVE window defaults.

	_RELEASE_MODE / _DEMO are copied onto globals in main.lua before boot.
	love.conf is only invoked when a root conf.lua exists; window/title are
	also applied at runtime via Game:init_window / apply_window_changes.
]]

local M = {
	RELEASE_MODE = false,
	DEMO = false,
}

function M.love_conf(t)
	t.console = not M.RELEASE_MODE
	t.window.title = "Jumbalaya"
	t.title = "Jumbalaya"
	-- Landscape defaults; width must exceed height so LÖVE picks landscape on mobile.
	t.window.width = 1280
	t.window.height = 720
	t.window.highdpi = true
	t.window.resizable = false
	t.window.minwidth = 100
	t.window.minheight = 100
end

return M