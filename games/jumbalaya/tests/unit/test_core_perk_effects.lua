local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local PerkEffects = require("jumbalaya_core.rules.perk_effects")

T.describe("jumbalaya_core perk effects", function()
	T.it("adds long word bonus points", function()
		local effects = PerkEffects.compute_word_effects("ABCDEF", {}, {}, { long_word = true })
		T.assert_equal(effects.bonus_points, 15)
	end)

	T.it("awards greedy bank multiplier for 3+ words", function()
		local j = { puzzle_words = { "A", "B", "C" } }
		T.assert_equal(PerkEffects.bank_total_multiplier(j, { greedy = true }), 1.2)
	end)
end)
