--[[ tests/unit/test_sprite_draw_stack.lua - Sprite transform cleanup ]] 

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

T.describe("Sprite draw transform cleanup", function()

	T.it("pops projected transform when rendering fails", function()
		MockEnv.setup()
		require("app.core.util.tables")
		require("app.core.object")
		require("app.core.scene.animated.init")
		require("app.core.graphics.sprite")

		local depth = 0
		local old_push = love.graphics.push
		local old_pop = love.graphics.pop
		local old_draw = love.graphics.draw
		love.graphics.push = function() depth = depth + 1 end
		love.graphics.pop = function() depth = depth - 1 end
		love.graphics.draw = function() error("forced draw failure") end

		local other = {
			T = { x = 0, y = 0, w = 1, h = 1 },
			VT = { x = 0, y = 0, w = 1, h = 1, scale = 1 },
			scale_mag = 1,
		}
		local sprite = {
			ARGS = {},
			atlas = { image = {} },
			sprite = {},
			draw_boundingrect = function() end,
		}

		local ok = pcall(Sprite.project_onto, sprite, other)
		love.graphics.push = old_push
		love.graphics.pop = old_pop
		love.graphics.draw = old_draw

		T.assert_false(ok, "The forced rendering error should be re-raised")
		T.assert_equal(depth, 0, "project_onto must balance its transform on failure")
	end)
end)