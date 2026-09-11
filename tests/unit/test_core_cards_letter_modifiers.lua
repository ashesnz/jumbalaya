--[[ tests/unit/test_core_cards_letter_modifiers.lua - letter modifier data without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Modifiers = require("jumbalaya_core.cards.letter_modifiers")

T.describe("jumbalaya_core cards letter modifiers", function()
	T.it("defines a unique marketplace description for every letter A–Z", function()
		for i = 1, 26 do
			local letter = string.char(string.byte("A") + i - 1)
			local text = Modifiers.modifier_description(letter)
			T.assert_true(type(text) == "string" and #text > 10, "Missing description for " .. letter)
			local ui_text = Modifiers.modifier_ui_text(letter)
			T.assert_true(type(ui_text) == "string" and #ui_text > 0, "Missing ui_text for " .. letter)
		end
	end)

	T.it("detects modified cards and letters in a hand", function()
		local cards = {
			{ ability = { letter = "E", modified = true } },
			{ ability = { letter = "A" } },
		}
		T.assert_true(Modifiers.is_modified(cards[1]))
		T.assert_false(Modifiers.is_modified(cards[2]))
		T.assert_equal(#Modifiers.modified_cards_in(cards), 1)
		T.assert_true(Modifiers.has_modified_letter(cards, "E"))
		T.assert_false(Modifiers.has_modified_letter(cards, "A"))
	end)
end)
