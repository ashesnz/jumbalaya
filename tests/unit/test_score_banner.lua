--[[ tests/unit/test_score_banner.lua
     Unit tests for points and multiplier bubble font, bounce/throb animations,
     multiplier growth scaling and capping, and score banner lifecycle.
]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

T.describe("Score Banner Bubble & Bounce Animations (word_game.ui.score_banner)", function()
	T.it("triggers independent bounce/throb animations on points and multiplier increases", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")
		sb.reset_jumble_score()

		T.assert_nil(sb.points_bounce, "points_bounce should be nil initially")
		T.assert_nil(sb.multi_bounce, "multi_bounce should be nil initially")

		-- Score increase with points and multi
		sb.roll_jumble_score(0, 5, 1.0, 1.2)
		T.assert_not_nil(sb.points_bounce, "points_bounce should be triggered on points increase")
		T.assert_not_nil(sb.multi_bounce, "multi_bounce should be triggered on multi increase")
		T.assert_equal(sb.points_bounce.t, 0)
		T.assert_equal(sb.multi_bounce.t, 0)

		-- Mid-bounce calculation produces scale > 1.0 (throb expansion)
		local pts_sx, pts_sy, pts_intensity = sb.calc_bounce(sb.points_bounce)
		T.assert_true(pts_sx >= 1.0, "Bounce scale should be >= 1.0")

		sb.points_bounce.t = sb.points_bounce.dur * 0.35
		local mid_sx, mid_sy, mid_intensity = sb.calc_bounce(sb.points_bounce)
		T.assert_true(mid_sx > 1.05, "Mid-bounce scale should throb/expand above 1.05")
		T.assert_true(mid_intensity > 0, "Mid-bounce intensity should be > 0")

		-- Advance update beyond bounce duration
		sb.update(sb.BOUNCE_DUR + 0.05)
		T.assert_nil(sb.points_bounce, "points_bounce should complete and reset to nil")
		T.assert_nil(sb.multi_bounce, "multi_bounce should complete and reset to nil")
	end)

	T.it("calculates progressive font growth for multi building and caps maximum size", function()
		local sb = require("word_game.ui.score_banner")

		local g_1x = sb.get_multi_growth(1.0)
		T.assert_almost_equal(g_1x, 1.0, 0.001, "Growth at 1.0x should be 1.0")

		local g_1_2x = sb.get_multi_growth(1.2)
		T.assert_true(g_1_2x > g_1x, "Growth at 1.2x should exceed 1.0x")

		local g_1_6x = sb.get_multi_growth(1.6)
		T.assert_true(g_1_6x > g_1_2x, "Growth at 1.6x should exceed 1.2x")

		local g_2_5x = sb.get_multi_growth(2.5)
		T.assert_true(g_2_5x > g_1_6x, "Growth at 2.5x should exceed 1.6x")

		-- Capping check: multi growth must not exceed maximum threshold (+28%)
		local g_10x = sb.get_multi_growth(10.0)
		local g_100x = sb.get_multi_growth(100.0)
		T.assert_almost_equal(g_10x, 1.28, 0.001, "Growth at high multi should be capped at 1.28")
		T.assert_almost_equal(g_100x, 1.28, 0.001, "Growth at extreme multi should be capped at 1.28")
	end)

	T.it("loads bubble font with graceful fallback and caches instances", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")

		local font24 = sb.bubble_font(24)
		T.assert_not_nil(font24, "bubble_font(24) should return a valid font")
		local font24_cached = sb.bubble_font(24)
		T.assert_equal(font24, font24_cached, "bubble_font should cache font objects by px size")

		local font32 = sb.bubble_font(32)
		T.assert_not_nil(font32, "bubble_font(32) should return a valid font")
	end)

	T.it("triggers opposite fast spins of 0.5s duration landing 45 degrees offset", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")
		sb.reset_jumble_score()

		T.assert_equal(sb.SPIN_DUR, 0.50, "SPIN_DUR should be 0.5 seconds")
		T.assert_nil(sb.points_spin, "points_spin should be nil initially")
		T.assert_nil(sb.multi_spin, "multi_spin should be nil initially")
		T.assert_equal(sb.points_rot, 0, "Initial points_rot should be 0")
		T.assert_equal(sb.multi_rot, 0, "Initial multi_rot should be 0")

		-- Trigger score update
		sb.roll_jumble_score(0, 4, 1.0, 1.4)

		T.assert_not_nil(sb.points_spin, "points_spin should be triggered on points increase")
		T.assert_not_nil(sb.multi_spin, "multi_spin should be triggered on multi increase")
		T.assert_equal(sb.points_spin.dur, 0.50)
		T.assert_equal(sb.multi_spin.dur, 0.50)

		-- Points rotates clockwise (positive delta), Multi rotates anti-clockwise (negative delta)
		T.assert_true(sb.points_spin.rot_delta > 0, "Points box rot_delta should be clockwise (positive)")
		T.assert_true(sb.multi_spin.rot_delta < 0, "Multi box rot_delta should be anti-clockwise (negative)")

		-- Check mid-spin rotation values
		sb.points_spin.t = 0.25
		sb.multi_spin.t = 0.25
		local mid_pts_rot = sb.calc_box_rotation(sb.points_spin, 0)
		local mid_mult_rot = sb.calc_box_rotation(sb.multi_spin, 0)
		T.assert_true(mid_pts_rot > 0, "Mid-spin points rotation should be clockwise")
		T.assert_true(mid_mult_rot < 0, "Mid-spin multi rotation should be anti-clockwise")

		-- Check end-spin landing: 45 degrees offset (pi/4)
		sb.points_spin.t = 0.50
		sb.multi_spin.t = 0.50
		local end_pts_rot = sb.calc_box_rotation(sb.points_spin, 0)
		local end_mult_rot = sb.calc_box_rotation(sb.multi_spin, 0)
		local pts_offset_deg = math.deg(end_pts_rot) % 90
		local mult_offset_deg = math.deg(end_mult_rot) % 90
		T.assert_almost_equal(pts_offset_deg, 45, 0.01, "Points box should land 45 degrees offset")
		T.assert_almost_equal(mult_offset_deg, 45, 0.01, "Multi box should land 45 degrees offset")

		-- Digit rotation completes full turns and settles upright
		local pts_digit_rot = sb.calc_digit_rotation(sb.points_spin)
		local mult_digit_rot = sb.calc_digit_rotation(sb.multi_spin)
		T.assert_almost_equal(math.deg(pts_digit_rot) % 360, 0, 0.01, "Points digit should land upright (0 deg)")
		T.assert_almost_equal(math.deg(mult_digit_rot) % 360, 0, 0.01, "Multi digit should land upright (0 deg)")

		-- Update past 0.5s duration
		sb.update(0.55)
		T.assert_nil(sb.points_spin, "points_spin should complete and reset to nil")
		T.assert_nil(sb.multi_spin, "multi_spin should complete and reset to nil")
	end)

	T.it("calculates doubled size for points and multi boxes with no overlap and gaps around X", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")

		local w = 500
		local h = 60
		local slant = 20
		local layout = sb.calc_layout(w, h, slant)

		-- Verify doubled size: box_size factor is ~1.68 of banner height (~100px vs old ~50px)
		T.assert_true(layout.box_size >= 95, "box_size should be doubled to ~100px")
		T.assert_true(layout.num_font_px >= 50, "num_font_px should be doubled proportionally")
		T.assert_true(layout.x_font_px >= 40, "x_font_px should be doubled proportionally")

		-- Verify positive gap
		T.assert_true(layout.gap >= 12, "gap between boxes and X should be at least 12px")

		-- Verify no overlap: distance between inner edges of boxes must be positive
		local points_right_edge = layout.chip_cx + layout.box_size * 0.5
		local multi_left_edge = layout.mult_cx - layout.box_size * 0.5
		local x_left_edge = -layout.x_tw * 0.5
		local x_right_edge = layout.x_tw * 0.5

		-- Points box is completely to the left of X with a gap
		T.assert_almost_equal(x_left_edge - points_right_edge, layout.gap, 0.01, "Gap between Points and X must equal layout.gap")
		-- Multi box is completely to the right of X with a gap
		T.assert_almost_equal(multi_left_edge - x_right_edge, layout.gap, 0.01, "Gap between X and Multi must equal layout.gap")
		-- Total box separation is 2 * gap + x_tw > 0 (strictly non-overlapping)
		T.assert_true(multi_left_edge > points_right_edge, "Points box and Multi box must not overlap")
	end)

	T.it("triggers comic burst explosions on the spinning square boxes rather than the X separator", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")
		sb.reset_jumble_score()

		T.assert_nil(sb.points_burst, "points_burst should be nil initially")
		T.assert_nil(sb.multi_burst, "multi_burst should be nil initially")

		-- Increase only points: points_burst spawns, multi_burst remains nil
		sb.roll_jumble_score(0, 3, 1.0, 1.0)
		T.assert_not_nil(sb.points_burst, "points_burst should trigger when points increase")
		T.assert_nil(sb.multi_burst, "multi_burst should not trigger when multi does not change")

		-- Reset and increase only multi: multi_burst spawns, points_burst remains nil
		sb.reset_jumble_score()
		sb.roll_jumble_score(3, 3, 1.0, 1.5)
		T.assert_nil(sb.points_burst, "points_burst should not trigger when points do not change")
		T.assert_not_nil(sb.multi_burst, "multi_burst should trigger when multi increases")

		-- Both change: both bursts spawn on their respective boxes
		sb.reset_jumble_score()
		sb.roll_jumble_score(0, 5, 1.0, 2.0)
		T.assert_not_nil(sb.points_burst, "points_burst should trigger on score change")
		T.assert_not_nil(sb.multi_burst, "multi_burst should trigger on score change")

		-- Advance update to test burst fade out and expiration
		sb.update(0.70)
		T.assert_nil(sb.points_burst, "points_burst should expire after hold+fade")
		T.assert_nil(sb.multi_burst, "multi_burst should expire after hold+fade")
	end)

	T.it("calculates points to get position centered between card area and dealt hand", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")

		local ts = 10
		_G.G.placement_table = {
			area = {
				T = { x = 2.0, y = 3.0, w = 6.0, h = 2.0 },
			},
		}
		_G.G.hand = {
			T = { x = 2.0, y = 7.0, w = 6.0, h = 2.0 },
		}

		local cx, cy = sb.calc_points_to_get_pos(100, ts)
		local card_bottom = (3.0 + 2.0) * ts -- 50
		local hand_top = 7.0 * ts -- 70
		local expected_cy = (card_bottom + hand_top) * 0.5 - ts * 0.35 -- 56.5

		T.assert_equal(cx, 100, "cx should match passed cx")
		T.assert_almost_equal(cy, expected_cy, 0.01, "cy should be exactly in the gap between card area bottom and hand top")
		T.assert_true(cy > card_bottom, "cy must be below the card area")
		T.assert_true(cy < hand_top, "cy must be above the dealt hand")
		T.assert_true(cy < (card_bottom + hand_top) * 0.5, "Points to get should be raised above bonus popups")
	end)

	T.it("disables and destroys the blue debug button", function()
		MockEnv.setup()
		local dbg = require("devtools.debug_button")

		T.assert_false(dbg.visible(), "Debug button must not be visible")
		dbg.ensure()
		T.assert_nil(_G.G.debug_toggle_button, "debug_toggle_button must not exist after ensure")
		dbg.sync()
		T.assert_nil(_G.G.debug_toggle_button, "debug_toggle_button must not exist after sync")
	end)

	T.it("renders score banner cleanly in jumble mode without errors", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")
		local jumble = require("word_game.model.jumble")

		_G.G.STATE = _G.G.STATES.TABLE_BOARD
		_G.WORD_GAME.Jumble = jumble
		_G.WORD_GAME.ScoreBanner = sb

		local wr = {
			target = 20,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				total_score = 0,
				puzzle_points = 2,
				puzzle_multi = 2.5,
				puzzle_words = {},
			},
		}
		_G.G.GAME.word_round = wr
		sb.reset_jumble_score()
		sb.roll_jumble_score(0, 2, 1.0, 2.5)

		local ok, err = pcall(sb.draw)
		T.assert_true(ok, "sb.draw should execute without error: " .. tostring(err))
	end)

	T.it("forms a separated arrowhead stack with aligned ribbon edges and non-touching gap", function()
		MockEnv.setup()
		local announce = require("word_game.ui.boss_word_announce")

		_G.G.STATE = _G.G.STATES.TABLE_BOARD
		_G.G.TILESCALE = 1
		_G.G.TILESIZE = 73
		_G.G.hand = {
			T = { x = 2.0, y = 7.0, w = 6.0, h = 2.0 },
			cards = {},
		}
		_G.G.TEXTURE_ATLASES = _G.G.TEXTURE_ATLASES or {}
		_G.G.TEXTURE_ATLASES.boss_banner = {
			image = {
				getDimensions = function() return 1180, 211 end,
			},
		}
		-- banner.png has more left padding than right; flipping around the
		-- texture midpoint used to leave Garden ~10–20px too far left.
		announce.set_content_bounds_for_test({ minx = 228, maxx = 993, miny = 15, maxy = 196 })

		announce.play_boss("BOSS WORD")
		announce.play_theme("Garden Theme")

		local stack = announce.measure_stack()
		T.assert_not_nil(stack, "stack layout should be measurable")
		T.assert_true(stack.ribbon_gap > 0, "boss and theme ribbons must not touch each other")
		T.assert_almost_equal(stack.ribbon_gap, stack.gap, 0.001,
			"visual gap between ribbons should match the configured banner gap")
		T.assert_true(stack.theme_top > stack.boss_bottom,
			"theme ribbon should sit below the boss ribbon without touching")

		local gap_px = stack.ribbon_gap * (_G.G.TILESCALE * _G.G.TILESIZE)
		T.assert_true(gap_px >= 10, "ribbon gap should be a visible separation in pixels")
		T.assert_true(stack.theme_cy > stack.boss_cy, "theme should be below boss")

		T.assert_almost_equal(stack.garden_top_left.x, stack.boss_bottom_left.x, 0.001,
			"Garden Theme top-left must line up with Boss Word bottom-left")
		T.assert_almost_equal(stack.garden_top_right.x, stack.boss_bottom_right.x, 0.001,
			"Garden Theme top-right must line up with Boss Word bottom-right")

		announce.clear()
		announce.set_content_bounds_for_test(nil)
	end)

	T.it("plays a theme banner on the countdown one mark", function()
		MockEnv.setup()
		local announce = require("word_game.ui.boss_word_announce")

		_G.G.STATE = _G.G.STATES.TABLE_BOARD
		_G.G.hand = {
			T = { x = 2.0, y = 7.0, w = 6.0, h = 2.0 },
			cards = {},
		}
		_G.G.TEXTURE_ATLASES = _G.G.TEXTURE_ATLASES or {}
		_G.G.TEXTURE_ATLASES.boss_banner = {
			image = {
				getDimensions = function() return 1180, 211 end,
			},
		}

		announce.play_boss("BOSS WORD")
		announce.play_theme("Garden Theme")
		T.assert_true(announce.is_active(), "both banners should be active")

		local ok, err = pcall(announce.draw_pass)
		T.assert_true(ok, "stacked banner draw should succeed: " .. tostring(err))

		announce.clear()
		T.assert_false(announce.is_active(), "clear should remove both banners")
	end)

	T.it("plays a full-width boss word ribbon sweep", function()
		MockEnv.setup()
		local announce = require("word_game.ui.boss_word_announce")
		local sb = require("word_game.ui.score_banner")

		_G.G.STATE = _G.G.STATES.TABLE_BOARD
		_G.G.GAME.word_hud = {}
		_G.G.hand = {
			T = { x = 2.0, y = 7.0, w = 6.0, h = 2.0 },
			cards = {},
		}
		_G.G.TEXTURE_ATLASES = _G.G.TEXTURE_ATLASES or {}
		_G.G.TEXTURE_ATLASES.boss_banner = {
			image = {
				getDimensions = function() return 1180, 211 end,
			},
		}

		T.assert_false(announce.is_active(), "announce should start inactive")
		sb.set_banner_mode("boss_word", "BOSS WORD")
		T.assert_true(announce.is_active(), "boss banner mode should trigger the sweep")

		sb.set_banner_mode("boss_word", "BOSS WORD")

		local ok, err = pcall(announce.draw_pass)
		T.assert_true(ok, "boss word announce draw should succeed: " .. tostring(err))

		announce.update(2.0)
		T.assert_true(announce.is_active(), "announce should persist after the sweep lands")

		sb.set_banner_mode("normal")
		T.assert_false(announce.is_active(), "announce should clear when boss mode ends")
	end)

	T.it("balances the graphics stack while showing boss banner text", function()
		MockEnv.setup()
		local sb = require("word_game.ui.score_banner")

		_G.G.STATE = _G.G.STATES.TABLE_BOARD
		_G.G.GAME.word_hud = {
			banner_mode = "boss_prep",
			banner_message = "Boss Level!",
		}

		local depth = 0
		local old_push = love.graphics.push
		local old_pop = love.graphics.pop
		love.graphics.push = function() depth = depth + 1 end
		love.graphics.pop = function() depth = depth - 1 end

		local ok, err = pcall(sb.draw)
		love.graphics.push = old_push
		love.graphics.pop = old_pop

		T.assert_true(ok, "boss banner draw should succeed: " .. tostring(err))
		T.assert_equal(depth, 0, "boss banner draw must balance push/pop")
	end)

	T.it("starts card bonus text below the card top", function()
		MockEnv.setup()
		local float_up_text = require("word_game.ui.float_up_text")
		local captured
		local original_spawn = float_up_text.spawn
		float_up_text.spawn = function(config)
			captured = config
			return config
		end

		float_up_text.from_card({ T = { x = 2, y = 3, w = 1, h = 2 } }, "+2")
		float_up_text.spawn = original_spawn

		T.assert_not_nil(captured, "card bonus text should be spawned")
		T.assert_true(captured.y > 3.16, "card bonus text should start below its previous origin")
		T.assert_almost_equal(captured.y, 3 + 2 * 0.08 + 0.65, 0.01,
			"card bonus text should use the direct start offset")
	end)
end)
