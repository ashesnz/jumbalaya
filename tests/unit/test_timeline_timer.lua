--[[
	tests/unit/test_timeline_timer.lua - Unit tests for mathematical timeline timer.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Timeline Timer & Shape Math", function()
	T.it("generates mathematical polygon vertices with rounded corners and slanted right edge", function()
		mock_env.reset_game()
		local tt = require("word_game.ui.perks.timeline_timer")
		local x, y, w, h, slant, r = 100, 50, 400, 40, 36, 6
		local verts = tt.build_shape_polygon(x, y, w, h, slant, r, 6)

		T.assert_true(#verts >= 16, "Should generate sufficient vertices for smooth polygon")
		T.assert_equal(#verts % 2, 0, "Vertex coordinates must be paired (x, y)")

		-- Check bounds: x-min should be x, x-max should be near x + w
		local min_x, max_x = math.huge, -math.huge
		local min_y, max_y = math.huge, -math.huge
		for i = 1, #verts, 2 do
			local vx, vy = verts[i], verts[i + 1]
			if vx < min_x then min_x = vx end
			if vx > max_x then max_x = vx end
			if vy < min_y then min_y = vy end
			if vy > max_y then max_y = vy end
		end

		T.assert_almost_equal(min_x, x, 0.1, "Minimum X must be at left edge")
		T.assert_almost_equal(max_x, x + w, 2.0, "Maximum X must reach bottom-right slanted edge")
		T.assert_almost_equal(min_y, y, 0.1, "Minimum Y must be at top edge")
		T.assert_almost_equal(max_y, y + h, 0.1, "Maximum Y must be at bottom edge")

		-- Test partial green polygon
		local green_half = tt.build_green_polygon(x, y, w, h, slant, r, 0.5, 6)
		T.assert_not_nil(green_half, "Halfway fraction should return polygon vertices")
		T.assert_true(#green_half >= 16)

		local green_zero = tt.build_green_polygon(x, y, w, h, slant, r, 0.0, 6)
		T.assert_nil(green_zero, "Zero fraction should return nil")
	end)

	T.it("initializes to 60s duration and decrements over 60 seconds", function()
		local tt = require("word_game.ui.perks.timeline_timer")
		tt.reset()
		T.assert_equal(tt.TOTAL_DURATION, 60.0)
		T.assert_equal(tt.time_remaining, 60.0)

		-- Update 15s
		tt.update(15.0)
		T.assert_almost_equal(tt.time_remaining, 45.0, 0.01)

		-- Update another 40s (total 55s)
		tt.update(40.0)
		T.assert_almost_equal(tt.time_remaining, 5.0, 0.01)

		-- Update 10s (reaches 0 and clamps)
		tt.update(10.0)
		T.assert_equal(tt.time_remaining, 0.0, "Timer must clamp at 0")
	end)

	T.it("resets back to 60s when a new hand is started", function()
		mock_env.reset_game()
		WORD_GAME.Sidebar = {
			refresh = function() end,
			clear_hand = function() end,
			sync_visibility = function() end,
		}
		local tt = require("word_game.ui.perks.timeline_timer")
		local round = require("word_game.model.round")
		WORD_GAME.TimelineTimer = tt

		tt.reset()
		tt.update(30.0)
		T.assert_almost_equal(tt.time_remaining, 30.0, 0.01)

		-- Start new hand
		round.start_hand(1, 1)
		T.assert_equal(tt.time_remaining, 60.0, "Timeline timer must reset to 60s on new hand")
		WORD_GAME.Sidebar = nil
	end)

	T.it("positions timeline rect above the score banner and matches card area width", function()
		local layout = require("word_game.ui.layout")
		local rect = layout.timeline_rect()
		local col = layout.play_column()

		T.assert_not_nil(rect)
		T.assert_true(rect.w > 4.0, "Timeline width must be sufficiently wide")
		T.assert_true(rect.h > 0.5, "Timeline height must be positive")
		T.assert_almost_equal(rect.x + rect.w * 0.5, col.x + col.w * 0.5, 0.01, "Timeline must be centered horizontally on play column")
		T.assert_almost_equal(rect.w, layout.card_area_width(), 0.001, "Timeline width must match card area width")
	end)


	T.it("formats countdown timer text with dynamic decimal precision under 10s and 5s", function()
		local tt = require("word_game.ui.perks.timeline_timer")
		-- >= 10s: whole number
		T.assert_equal(tt.format_time(60.0), "60")
		T.assert_equal(tt.format_time(45.2), "45")
		T.assert_equal(tt.format_time(10.0), "10")

		-- < 10s and >= 5s: 1 decimal place (9.9 onwards)
		T.assert_equal(tt.format_time(9.9), "9.9")
		T.assert_equal(tt.format_time(9.0), "9.0")
		T.assert_equal(tt.format_time(7.42), "7.4")
		T.assert_equal(tt.format_time(5.0), "5.0")

		-- < 5s: 2 decimal places
		T.assert_equal(tt.format_time(4.99), "4.99")
		T.assert_equal(tt.format_time(4.5), "4.50")
		T.assert_equal(tt.format_time(1.234), "1.23")
		T.assert_equal(tt.format_time(0.05), "0.05")
		T.assert_equal(tt.format_time(0.0), "0.00")
		T.assert_equal(tt.format_time(-1.0), "0.00")
	end)

	T.it("freezes reward display to whole seconds matching token count", function()
		local tt = require("word_game.ui.perks.timeline_timer")
		tt.reset()
		tt.update(49.2)
		tt.freeze_reward_display(math.floor(49.2))
		T.assert_equal(tt.time_remaining, 49)
		T.assert_false(tt.is_active)
		T.assert_true(tt.frozen_for_reward)
		T.assert_equal(tt.format_time(tt.time_remaining), "49")
	end)

	T.it("shows classic score progress instead of a countdown timer", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		G.GAME.word_round = {
			target = 50,
			jumble = { total_score = 18, puzzle_points = 4, puzzle_multi = 2.0, puzzle_words = {} },
		}
		tt.reset_progress(50)
		tt.sync_progress()
		T.assert_true(tt.is_progress_mode())
		T.assert_equal(tt.format_progress_label(), "26 / 50")
		T.assert_almost_equal(tt.progress_fill_fraction(), 0.36, 0.01)
		T.assert_almost_equal(tt.progress_total_fraction(), 0.52, 0.01)
		T.assert_false(tt.is_active, "Classic mode must not run a countdown timer")
	end)

	T.it("keeps the slider width fixed and slides the goal seam left after target is exceeded", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		G.GAME.word_round = {
			target = 25,
			jumble = { total_score = 50, puzzle_points = 0, puzzle_multi = 1.0, puzzle_words = {} },
		}
		tt.reset_progress(25)
		tt.sync_progress()
		T.assert_true(tt.goal_reached)
		T.assert_almost_equal(tt.progress_total_fraction(), 1, 0.001, "Fill should cap at full width")
		T.assert_almost_equal(tt.progress_goal_marker_fraction(), 0.5, 0.001, "Goal seam should move left as score doubles")
		T.assert_equal(tt.format_progress_label(), "50 / 25")

		G.GAME.word_round.jumble.total_score = 100
		tt.sync_progress()
		T.assert_almost_equal(tt.progress_goal_marker_fraction(), 0.25, 0.001, "More score should push the goal seam further left")
	end)

	T.it("animates the slider toward projected score on each word play", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		G.GAME.word_round = {
			target = 50,
			jumble = {
				total_score = 0,
				puzzle_points = 3,
				puzzle_multi = 1.0,
				puzzle_words = { "CAT" },
			},
		}
		tt.reset_progress(50)
		tt.display_frac = 0
		tt.on_word_played(0, 3)
		T.assert_almost_equal(tt.progress_total_fraction(), 3 / 50, 0.01)
		tt.update(0.25)
		T.assert_true(tt.display_frac > 0, "Slider should advance after a word is played")
		T.assert_true(tt.display_frac < 3 / 50 + 0.01, "Slider should lerp toward projected score")
		T.assert_equal(tt.format_progress_label(), "3 / 50", "Label should include in-progress puzzle score")
	end)

	T.it("engages smoke only after the third word on the same puzzle", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")

		local function sync_words(words)
			G.GAME.word_round = {
				target = 50,
				jumble = {
					total_score = 0,
					puzzle_points = #words * 3,
					puzzle_multi = 1.0,
					puzzle_words = words,
				},
			}
			tt.reset_progress(50)
			tt.sync_progress()
		end

		sync_words({ "CAT" })
		T.assert_false(tt.smoke_active, "First word on a puzzle must not smoke")
		sync_words({ "CAT", "CART" })
		T.assert_false(tt.smoke_active, "Second word on a puzzle must not smoke")
		sync_words({ "CAT", "CART", "CREST" })
		T.assert_true(tt.smoke_active, "Third word on a puzzle should engage smoke")
	end)

	T.it("resets smoke when advancing to a new puzzle", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		G.GAME.word_round = {
			target = 50,
			jumble = {
				total_score = 0,
				puzzle_points = 9,
				puzzle_multi = 1.0,
				puzzle_words = { "CAT", "CART", "CREST" },
			},
		}
		tt.reset_progress(50)
		tt.sync_progress()
		tt.display_combo = 3
		T.assert_true(tt.smoke_active)
		table.insert(tt.sparks, { age = 0, life = 1, x = 0, y = 0, vx = 0, vy = 0, alpha = 1, size = 3, color = { 1, 1, 1, 1 } })

		tt.reset_puzzle_smoke()
		G.GAME.word_round.jumble.puzzle_words = {}
		tt.sync_progress()
		T.assert_false(tt.smoke_active)
		T.assert_true(tt.display_combo_level() > 0, "Smoke and glow should ease out instead of snapping off")
		for _ = 1, 30 do
			tt.update_display_intensity(0.1)
		end
		T.assert_almost_equal(tt.display_combo_level(), 0, 0.05, "Intensity should settle back to calm")
	end)

	T.it("eases vibration down after a high combo puzzle ends", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		G.GAME.word_round = {
			target = 50,
			jumble = {
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = { "A", "B", "C", "D", "E", "F" },
			},
		}
		tt.reset_progress(50)
		tt.sync_progress()
		tt.display_combo = tt.combo_level()
		T.assert_true(tt.display_shake_strength() > 0)

		G.GAME.word_round.jumble.puzzle_words = {}
		tt.sync_progress()
		T.assert_true(tt.display_shake_strength() > 0, "Shake should linger briefly after the puzzle resets")
		for _ = 1, 40 do
			tt.update_display_intensity(0.1)
		end
		T.assert_almost_equal(tt.display_shake_strength(), 0, 0.05, "Shake should ease back to still")
	end)

	T.it("escalates glow, smoke, and shake after the third consecutive word", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")

		local function sync_words(words)
			G.GAME.word_round = {
				target = 50,
				jumble = {
					total_score = 0,
					puzzle_points = #words * 3,
					puzzle_multi = 1.0,
					puzzle_words = words,
				},
			}
			tt.reset_progress(50)
			tt.sync_progress()
		end

		sync_words({ "CAT", "CART", "CREST" })
		local level3_glow = tt.smoke_glow_scale()
		local level3_cap = tt.smoke_particle_cap()
		T.assert_equal(tt.combo_level(), 1)
		T.assert_equal(tt.shake_strength(), 0)

		sync_words({ "CAT", "CART", "CREST", "CREAM" })
		T.assert_equal(tt.combo_level(), 2)
		T.assert_true(tt.smoke_glow_scale() > level3_glow, "Fourth word should enlarge the seam glow")
		T.assert_true(tt.smoke_particle_cap() > level3_cap, "Fourth word should allow more smoke particles")
		T.assert_equal(tt.shake_strength(), 0, "Shake should not start until the fifth word")

		sync_words({ "CAT", "CART", "CREST", "CREAM", "CREEP" })
		T.assert_equal(tt.combo_level(), 3)
		T.assert_true(tt.smoke_glow_scale() > level3_glow)
		T.assert_true(tt.shake_strength() > 0, "Fifth word should start shaking the timer bar")

		sync_words({ "CAT", "CART", "CREST", "CREAM", "CREEP", "CREED" })
		T.assert_equal(tt.combo_level(), 4)
		T.assert_true(tt.shake_strength() > 1.6, "Sixth word should shake harder than the fifth")
	end)

	T.it("resets to a score slider on new classic hands", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		WORD_GAME.Sidebar = {
			refresh = function() end,
			clear_hand = function() end,
			sync_visibility = function() end,
		}
		local tt = require("word_game.ui.perks.timeline_timer")
		local round = require("word_game.model.round")
		WORD_GAME.TimelineTimer = tt
		G.GAME.word_round = { set = 1, hand_index = 1, target = 25, played_words = {} }

		round.start_hand(1, 1)
		T.assert_true(tt.is_progress_mode())
		T.assert_equal(tt.progress_target, 25)
		T.assert_equal(tt.progress_score, 0)
		WORD_GAME.Sidebar = nil
	end)

	T.it("pauses countdown until resumed or reset", function()
		mock_env.reset_game()
		G.GAME.run_mode = "time_run"
		local tt = require("word_game.ui.perks.timeline_timer")
		tt.reset()
		tt.update(10.0)
		T.assert_almost_equal(tt.time_remaining, 50.0, 0.01)
		tt.pause()
		tt.update(5.0)
		T.assert_almost_equal(tt.time_remaining, 50.0, 0.01, "Paused timer must not decrement")
		tt.reset(60.0)
		T.assert_equal(tt.time_remaining, 60.0)
		T.assert_true(tt.is_active)
	end)

	T.it("syncs stage label when a new hand is started", function()
		mock_env.reset_game()
		WORD_GAME.Sidebar = {
			refresh = function() end,
			clear_hand = function() end,
			sync_visibility = function() end,
		}
		local stage_label = require("word_game.ui.stage_label")
		local round = require("word_game.model.round")
		stage_label.force_sync()
		stage_label.left_count = 1
		stage_label.right_count = 1
		round.start_hand(1, 3)
		T.assert_equal(stage_label.left_count, 1)
		T.assert_equal(stage_label.right_count, 3)
		WORD_GAME.Sidebar = nil
	end)

	T.it("rolls stage label digits when advancing to the next hand", function()
		local stage_label = require("word_game.ui.stage_label")
		G.GAME = G.GAME or {}
		G.GAME.word_round = { set = 1, hand_index = 1 }
		stage_label.force_sync()
		stage_label.roll_to_next_hand()
		T.assert_not_nil(stage_label.right_roll, "Hand digit should roll on advance")
		T.assert_equal(stage_label.right_roll.from, 1)
		T.assert_equal(stage_label.right_roll.to, 2)
		stage_label.update(0.15)
		T.assert_not_nil(stage_label.right_roll, "Roll should still be in progress mid-animation")
		stage_label.update(0.30)
		T.assert_nil(stage_label.right_roll, "Roll should finish after full duration")
		T.assert_equal(stage_label.right_count, 2)
	end)

	T.it("hides the slider then arms a 60s countdown that scales back in", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		G.GAME.word_round = {
			target = 50,
			jumble = { total_score = 18, puzzle_points = 0, puzzle_multi = 1.0, puzzle_words = {} },
		}
		tt.reset_progress(50)
		T.assert_true(tt.is_progress_mode())
		T.assert_equal(tt.intro_visible, 1)

		local hidden = false
		tt.hide_slider(0.4, function() hidden = true end)
		T.assert_false(hidden)
		T.assert_not_nil(tt.intro_anim, "Slider hide should start an intro animation")
		tt.update(0.05)
		T.assert_true(tt.intro_visible < 1, "Slider should start scaling out on the first update")
		tt.update(0.45)
		T.assert_true(hidden)
		T.assert_almost_equal(tt.intro_visible, 0, 0.01)

		tt.arm_boss_countdown(60)
		T.assert_false(tt.is_progress_mode(), "Boss intro must force the 60s fuse even in classic")
		T.assert_equal(tt.TOTAL_DURATION, 60)
		T.assert_equal(tt.time_remaining, 60)
		T.assert_equal(tt.intro_visible, 0)
		T.assert_false(tt.is_active)

		local shown = false
		tt.reveal_countdown_timer(0.4, function() shown = true end)
		T.assert_true(tt.is_active, "Timer should start when the fuse appears")
		tt.update(0.5)
		T.assert_true(shown)
		T.assert_almost_equal(tt.intro_visible, 1, 0.01)
		T.assert_true(tt.time_remaining < 60, "Armed fuse should tick once revealed")
		T.assert_true(tt.time_remaining > 59, "Reveal should not burn a large chunk of the 60s")
	end)

	T.it("clears the boss countdown override when a new classic hand starts", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.perks.timeline_timer")
		tt.arm_boss_countdown(60)
		T.assert_false(tt.is_progress_mode())
		T.assert_equal(tt.intro_visible, 0)
		tt.reset_progress(25)
		T.assert_true(tt.is_progress_mode())
		T.assert_equal(tt.intro_visible, 1)
		T.assert_false(tt.countdown_override)
	end)
end)
