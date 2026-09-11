--[[ tests/unit/test_core_jumble_rules.lua - jumbalaya_core rules without G or Love2D engine ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Core = require("jumbalaya_core")
local Rules = Core.Rules.Jumble
local PerkMath = Core.Rules.PerkMath

T.describe("jumbalaya_core jumble rules", function()
	T.it("counts placed cards in span and blank slots", function()
		local slots = {
			{ kind = "fixed", letter = "C" },
			{ kind = "blank", card = { ability = { letter = "A" } } },
			{ kind = "span", cards = { { ability = { letter = "T" } } } },
		}
		T.assert_equal(Rules.placed_count(slots), 2)
	end)

	T.it("reads round target from word_round with fallback", function()
		T.assert_equal(Rules.round_target({ target = 50 }), 50)
		T.assert_equal(Rules.round_target(nil, 20), 20)
	end)

	T.it("scores words by letter count with default 0.2x combo ramp", function()
		local wr = Core.Fixtures.jumble_word_round({
			puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
		})
		local j = wr.jumble
		local opts = { wr = wr, perks = {} }

		local old1, new1, _, m1 = Rules.apply_puzzle_word(j, "CAT", opts)
		T.assert_equal(old1, 0)
		T.assert_equal(new1, 3)
		T.assert_almost_equal(m1, 1.0, 0.01)

		local old2, new2, _, m2 = Rules.apply_puzzle_word(j, "CENT", opts)
		T.assert_equal(old2, 3)
		T.assert_equal(new2, 7)
		T.assert_almost_equal(m2, 1.2, 0.01)

		local old3, new3, _, m3 = Rules.apply_puzzle_word(j, "CHAT", opts)
		T.assert_equal(old3, 7)
		T.assert_equal(new3, 11)
		T.assert_almost_equal(m3, 1.4, 0.01)
	end)

	T.it("floors puzzle total with math.floor(points * multi)", function()
		local j = { puzzle_points = 15, puzzle_multi = 1.6, total_score = 0 }
		T.assert_equal(Rules.puzzle_total(j), 24)
	end)

	T.it("exposes perk math independent of G", function()
		T.assert_almost_equal(PerkMath.puzzle_multi_for_word_count(2, { combo_starter = true }), 1.4, 0.01)
		T.assert_almost_equal(PerkMath.puzzle_multi_for_word_count(3, { combo_master = true }), 1.6, 0.01)
	end)

	T.it("uses hand targets from core config", function()
		local round_cfg = Core.Config.Gameplay.Round
		T.assert_equal(round_cfg.hand_target(1, 1), 25)
		T.assert_equal(round_cfg.hand_target(1, 2), 50)
	end)

	T.it("creates store default state without G", function()
		local store = Core.Store.new()
		T.assert_not_nil(store:get().word_round)
		T.assert_equal(store:get().word_round.set, 1)
	end)
end)
