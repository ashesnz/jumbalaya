--[[ tests/unit/test_core_cards_identity.lua - card identity helpers without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Identity = require("jumbalaya_core.cards.identity")

T.describe("jumbalaya_core cards identity", function()
	T.it("builds stable face keys", function()
		T.assert_equal(Identity.front_key("a", "red"), "red_A")
		T.assert_equal(Identity.front_key("Z", "gold"), "gold_Z")
		T.assert_equal(Identity.front_key("B", "unknown"), "black_B")
	end)

	T.it("builds control tables for letter faces", function()
		local control = Identity.control_for_letter("C", "modified")
		T.assert_equal(control.key, "modified_C")
		T.assert_equal(control.letter, "C")
		T.assert_equal(control.letter_color, "modified")
	end)

	T.it("detects letter cards by ability letter", function()
		T.assert_true(Identity.is_letter_card({ ability = { letter = "Q" } }))
		T.assert_false(Identity.is_letter_card({ ability = { letter = "QU" } }))
		T.assert_false(Identity.is_letter_card({}))
	end)

	T.it("delegates rank id lookup to dictionary cards", function()
		T.assert_equal(Identity.letter_from_id(1), "A")
		T.assert_equal(Identity.letter_from_id(26), "Z")
	end)
end)
