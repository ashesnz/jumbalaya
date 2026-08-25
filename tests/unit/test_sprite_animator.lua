--[[ tests/unit/test_sprite_animator.lua - SpriteAnimator lifecycle ]] 

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

T.describe("SpriteAnimator lifecycle", function()

	T.it("normalizes a missing frame count", function()
		MockEnv.setup()
		G.LIVE = { SPRITE = {}, TRANSFORM = {}, NODE = {} }
		G.TRANSFORMS = {}
		G.ANIMATIONS = {}
		G.ANIMATION_FPS = 10
		G.ANIM_SHEETS = {}
		require("app.core.util.tables")
		require("app.core.object")
		require("app.core.scene.animated.init")
		require("app.core.graphics.sprite")
		require("app.core.graphics.sprite_animator")

		local atlas = {
			px = 4, py = 4, frames = 0,
			image = { getDimensions = function() return 4, 4 end },
		}
		local animator = SpriteAnimator(0, 0, 1, 1, atlas, {x = 0, y = 0})

 		T.assert_equal(animator.animation.frames, 1, "frame count must be safe for modulo")
 		animator:configure_frames(2, 3)
 		T.assert_equal(animator.animation.x, 2, "configuration should select the requested column")
 		T.assert_equal(animator.animation.y, 3, "configuration should select the requested row")
		T.assert_equal(animator:frame_at_time(0.24, 10, 4), 2, "frame selection should use elapsed time and rate")
		T.assert_equal(animator:frame_at_time(-1, 10, 4), 0, "negative elapsed time should clamp to the first frame")
		T.assert_equal(animator.sprite_pos.x, 2, "sprite position should follow the configured animation column")
		animator:draw_self()
		T.assert_equal(animator.animation.y, 3, "base rendering must preserve the animation row")
		animator:remove()
		T.assert_equal(#G.ANIMATIONS, 0, "remove must unregister the animator")
		T.assert_equal(#G.LIVE.SPRITE, 0, "remove must unregister the sprite")
	end)
end)