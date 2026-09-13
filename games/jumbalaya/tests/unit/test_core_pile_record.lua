--[[ tests/unit/test_core_pile_record.lua - pile record serialization and counting ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local pile_record = require("jumbalaya_core.cards.pile_record")
local pile_counts = require("jumbalaya_core.cards.pile_counts")

T.describe("jumbalaya_core pile records", function()
	T.it("serializes live cards without presentation fields", function()
		local record = pile_record.from_live_card({
			letter_card_id = 7,
			slot_index = 2,
			ability = { letter = "Q", letter_color = "red" },
			T = { x = 1, y = 2 },
		}, "pattern", 2)
		T.assert_equal(record.id, 7)
		T.assert_equal(record.pile_id, "pattern")
		T.assert_equal(record.slot_index, 2)
		T.assert_equal(record.ability.letter, "Q")
		T.assert_nil(record.T)
	end)

	T.it("counts sparse pattern piles by occupied slots", function()
		local pattern = { [2] = { id = 1 }, [5] = { id = 2 } }
		T.assert_equal(pile_record.count(pattern), 2)
		T.assert_equal(pile_counts.placement_count(pattern), 2)
	end)

	T.it("detects plain records vs live card tables", function()
		T.assert_true(pile_record.is_record({ id = 1, ability = {} }))
		T.assert_false(pile_record.is_record({ T = {}, id = 1 }))
	end)
end)
