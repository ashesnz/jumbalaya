--[[ tests/unit/test_window_landscape.lua
     Mobile landscape dimension helpers.
]]

local T = require("tests.framework")

T.describe("Mobile landscape window helpers", function()
	local Window = require("app.core.platform.window")

	T.it("swaps portrait dimensions to landscape", function()
		local w, h = Window.landscape_dimensions(390, 844)
		T.assert_equal(w, 844, "width should be the long edge")
		T.assert_equal(h, 390, "height should be the short edge")
	end)

	T.it("leaves landscape dimensions unchanged", function()
		local w, h = Window.landscape_dimensions(844, 390)
		T.assert_equal(w, 844)
		T.assert_equal(h, 390)
	end)

	T.it("handles square dimensions", function()
		local w, h = Window.landscape_dimensions(720, 720)
		T.assert_equal(w, 720)
		T.assert_equal(h, 720)
	end)

	T.it("uses logical getDimensions for backbuffer sizing", function()
		love.graphics.getDimensions = function()
			return 926, 428
		end

		local w, h = Window.get_backbuffer_dimensions()
		T.assert_equal(w, 926, "canvas should match logical width")
		T.assert_equal(h, 428, "canvas should match logical height")
	end)

	T.it("lock_landscape_orientation always uses fixed landscape setMode size", function()
		local set_w, set_h, set_flags
		love.window = love.window or {}
		love.window.setMode = function(w, h, flags)
			set_w, set_h, set_flags = w, h, flags
		end
		love.system = love.system or {}
		love.system.getOS = function() return "iOS" end

		local ok = Window.lock_landscape_orientation()
		T.assert_true(ok)
		T.assert_equal(set_w, 1280)
		T.assert_equal(set_h, 720)
		T.assert_equal(set_flags.resizable, false)
		T.assert_equal(set_flags.fullscreen, false)
	end)

	T.it("love.resize tolerates missing ROOM_PADDING before init_window", function()
		love.system = love.system or {}
		love.system.getOS = function() return "iOS" end
		_G.G = _G.G or {}
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.ROOM_PADDING_W = nil
		G.ROOM_PADDING_H = nil
		G.ROOM = nil

		local ok, err = pcall(love.resize, 926, 428)
		T.assert_true(ok, "resize must not error before init_window: " .. tostring(err))
		T.assert_not_nil(G.CANVAS, "canvas should be created even when padding is unset")
	end)
end)
