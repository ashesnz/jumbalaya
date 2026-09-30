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

	T.it("C…T stays three tiles for CAT, expands for CENT, and resets after play", function()
		local puzzle = PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 })
		local slots = Slots.parse_slots(puzzle)
		local j = { puzzle = puzzle, slots = slots }
		local span
		for _, slot in ipairs(slots) do
			if slot.kind == "span" then
				span = slot
				break
			end
		end
		T.assert_not_nil(span)
		T.assert_equal(Topology.span_active_len(j), 3, "empty C _ T shows three tiles")
		local items = Topology.fixed_letter_items(j)
		T.assert_equal(items[1].char, "C")
		T.assert_equal(items[1].pos, 1)
		T.assert_equal(items[#items].char, "T")
		T.assert_equal(items[#items].pos, 3)
		local cells = Topology.span_cells(j)
		T.assert_equal(cells[1].kind, "fixed")
		T.assert_equal(cells[2].kind, "empty")
		T.assert_equal(cells[2].char, "_")
		T.assert_equal(cells[3].kind, "fixed")

		span.cards = { { ability = { letter = "A" } } }
		T.assert_equal(Topology.span_active_len(j), 3, "CAT still uses three tiles")
		cells = Topology.span_cells(j)
		T.assert_equal(#cells, 3)
		T.assert_equal(cells[1].kind, "fixed")
		T.assert_equal(cells[2].kind, "card")
		T.assert_equal(cells[3].kind, "fixed")
		items = Topology.fixed_letter_items(j)
		T.assert_equal(items[#items].pos, 3)
		T.assert_equal(Topology.span_insert_pos(j, 2, false), 1, "drop left of A stays a 3-letter word")

		span.cards = { { ability = { letter = "A" } }, { ability = { letter = "R" } } }
		cells = Topology.span_cells(j)
		T.assert_equal(#cells, 4, "CART expands with no leftover _")
		T.assert_equal(cells[1].kind, "fixed")
		T.assert_equal(cells[2].kind, "card")
		T.assert_equal(cells[3].kind, "card")
		T.assert_equal(cells[4].kind, "fixed")

		span.cards = {}
		cells = Topology.span_cells(j)
		T.assert_equal(cells[2].kind, "empty")
		T.assert_equal(cells[2].char, "_")
		T.assert_equal(Topology.span_insert_pos(j, 2, true), 1, "first letter after play fills C_T")

		span.cards = { { ability = { letter = "E" } } }
		cells = Topology.span_cells(j)
		T.assert_equal(#cells, 3, "CET stays three tiles")
		T.assert_equal(cells[2].kind, "card")
		T.assert_equal(Topology.span_insert_pos(j, 2, true), 2, "N to the right of E is CENT")
		T.assert_equal(Topology.span_insert_pos(j, 2, false), 1, "N to the left of E is CNET")
		T.assert_equal(Topology.span_insert_pos(j, 1, true), 1, "drop on C inserts at the left")
		T.assert_equal(Topology.span_insert_pos(j, 3, false), 2, "drop on T appends")

		Slots.clear_blank_cards(slots)
		j.puzzle_words = { "CAT" }
		cells = Topology.span_cells(j)
		T.assert_equal(cells[2].kind, "empty", "after Play, empty row is C _ T")

		local ghost = { ability = { letter = "A" } }
		local e = { ability = { letter = "E" } }
		span.cards = { ghost }
		cells = Topology.span_cells(j, { e })
		T.assert_equal(#cells, 3, "stale A from last word must not widen CET")
		T.assert_equal(cells[2].card, e)
		T.assert_equal(cells[1].kind, "fixed")
		T.assert_equal(cells[3].kind, "fixed")

		span.cards = {}
		j.puzzle_words = {}
		T.assert_equal(Topology.span_active_len(j), 3, "fresh puzzle shows C _ T again")
		items = Topology.fixed_letter_items(j)
		T.assert_equal(items[#items].pos, 3)

		span.cards = { { ability = { letter = "E" } }, { ability = { letter = "N" } } }
		T.assert_equal(Topology.span_active_len(j), 4, "CENT expands to four tiles")
		items = Topology.fixed_letter_items(j)
		T.assert_equal(items[1].pos, 1)
		T.assert_equal(items[#items].pos, 4)

		Slots.clear_blank_cards(slots)
		T.assert_equal(Topology.span_active_len(j), 3, "clearing CENT returns to three tiles")
		items = Topology.fixed_letter_items(j)
		T.assert_equal(items[#items].pos, 3)
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

	T.it("shows _ N T until a letter is placed, then packs ANT", function()
		local puzzle = PuzzleSpec.resolve_puzzle({ suffix = "NT", min = 3, max = 7 })
		local slots = Slots.parse_slots(puzzle)
		local j = { puzzle = puzzle, slots = slots }
		local cells = Topology.span_cells(j)
		T.assert_equal(#cells, 3)
		T.assert_equal(cells[1].kind, "empty")
		T.assert_equal(cells[1].char, "_")
		T.assert_equal(cells[2].char, "N")
		T.assert_equal(cells[3].char, "T")

		local span = slots[1]
		span.cards = { { ability = { letter = "A" } } }
		cells = Topology.span_cells(j)
		T.assert_equal(#cells, 3)
		T.assert_equal(cells[1].kind, "card")
		T.assert_equal(cells[2].kind, "fixed")
		T.assert_equal(cells[3].kind, "fixed")
	end)

	T.it("drops leftover _ holes on a prefix puzzle once any letter is placed", function()
		local puzzle = PuzzleSpec.resolve_puzzle({ prefix = "C", min = 3, max = 7 })
		local slots = Slots.parse_slots(puzzle)
		local j = { puzzle = puzzle, slots = slots }
		local cells = Topology.span_cells(j)
		T.assert_equal(cells[1].char, "C")
		T.assert_equal(cells[2].kind, "empty")
		T.assert_equal(cells[3].kind, "empty")

		local span = slots[2]
		span.cards = { { ability = { letter = "A" } } }
		cells = Topology.span_cells(j)
		T.assert_equal(#cells, 2, "CA has no leftover _")
		T.assert_equal(cells[1].kind, "fixed")
		T.assert_equal(cells[2].kind, "card")
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
