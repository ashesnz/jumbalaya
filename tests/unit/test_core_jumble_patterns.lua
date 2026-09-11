--[[ tests/unit/test_core_jumble_patterns.lua - jumbalaya_core jumble patterns without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Core = require("jumbalaya_core")
local PuzzleSpec = Core.Jumble.PuzzleSpec
local Slots = Core.Jumble.Slots
local Topology = Core.Jumble.SlotTopology
local Validation = Core.Jumble.Validation

T.describe("jumbalaya_core jumble patterns", function()
	local function dict_opts()
		local Dictionary = require("dictionary")
		Dictionary.load()
		return {
			is_valid_word = function(word) return Dictionary.is_valid(word) end,
			for_each_word = function(min_len, max_len, fn)
				return Dictionary.for_each_word(min_len, max_len, fn)
			end,
		}
	end

	T.it("resolves and matches span anchor patterns", function()
		local opts = dict_opts()
		local p_span = PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 })
		T.assert_true(PuzzleSpec.word_fits_pattern("CAT", p_span, opts))
		T.assert_false(PuzzleSpec.word_fits_pattern("CAR", p_span, opts))

		local p_prefix = PuzzleSpec.resolve_puzzle({ prefix = "C", min = 3, max = 7 })
		T.assert_true(PuzzleSpec.word_fits_pattern("CAT", p_prefix, opts))
		T.assert_false(PuzzleSpec.word_fits_pattern("BAT", p_prefix, opts))
	end)

	T.it("assigns center slot index for center-only puzzles", function()
		local j = {
			puzzle = { center = "L", min = 3, max = 7, kind = "span" },
			slots = { { kind = "span", cards = {}, min = 1, max = 7 } },
		}
		T.assert_equal(Topology.center_slot_index(j, 0), 2)
		local items = Topology.fixed_letter_items(j, 3)
		T.assert_equal(items[1].pos, 2)
	end)

	T.it("parses span slots with pinned center", function()
		local puzzle = PuzzleSpec.resolve_puzzle({ center = "L", pin_index = 2, min = 3, max = 7 })
		local slots = Slots.parse_slots(puzzle)
		T.assert_equal(#slots, 3)
		T.assert_equal(slots[1].max, 1)
		T.assert_equal(slots[3].max, 5)
	end)

	T.it("computes span active length for suffix anchors", function()
		local p_ar = PuzzleSpec.resolve_puzzle({ suffix = "AR", min = 3, max = 7 })
		local j = {
			puzzle = p_ar,
			slots = {
				{ kind = "span", cards = {}, min = 1, max = 5 },
				{ kind = "fixed", anchor = "suffix", letter = "AR" },
			},
		}
		T.assert_equal(Topology.span_active_len(j), 3)
		table.insert(j.slots[1].cards, { ability = { letter = "C" } })
		T.assert_equal(Topology.span_active_len(j), 3)
		table.insert(j.slots[1].cards, { ability = { letter = "T" } })
		T.assert_equal(Topology.span_active_len(j), 4)
	end)

	T.it("validates unfilled blanks without G", function()
		local puzzle = PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7, kind = "span" })
		local slots = {
			{ kind = "fixed", letter = "C" },
			{ kind = "span", cards = {}, min = 1, max = 5 },
			{ kind = "fixed", letter = "T" },
		}
		local word, err = Validation.validate_word(slots, puzzle, dict_opts())
		T.assert_nil(word)
		T.assert_equal(err, "Must play a word or skip entirely")
	end)

	T.it("reports letters needed from hand for span puzzles", function()
		local puzzle = PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 })
		local needed = Validation.letters_needed_from_hand("CAT", puzzle)
		T.assert_equal(needed.A, 1)
	end)
end)
