--[[ tests/unit/test_jumble_patterns.lua
     Pattern validation, slots, and geometry tests for jumble puzzles.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Jumble pattern validation and geometry", function()
	mock_env.reset_game()
	local jumble = require("word_game.model.jumble")

	T.it("matches span and prefix/suffix anchor patterns correctly", function()
		Dictionary.load()
		local p_span = jumble.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 })
		T.assert_true(jumble.word_fits_pattern("CAT", p_span), "CAT fits C..T span")
		T.assert_false(jumble.word_fits_pattern("CAR", p_span), "CAR does not end in T")

		local p_prefix = jumble.resolve_puzzle({ prefix = "C", min = 3, max = 7 })
		T.assert_true(jumble.word_fits_pattern("CAT", p_prefix), "CAT starts with C")
		T.assert_false(jumble.word_fits_pattern("BAT", p_prefix), "BAT does not start with C")
	end)

	T.it("assigns a distinct fixed slot to a center-only letter", function()
		local j = {
			puzzle = { center = "L", min = 3, max = 7, kind = "span" },
			slots = { { kind = "span", cards = {}, min = 1, max = 7 } },
		}

		T.assert_equal(jumble.center_slot_index(j, 0), 2, "Center letter should reserve the middle slot")
		local items = jumble.fixed_letter_items(j, 3)
		T.assert_equal(items[1].pos, 2, "Fixed L should be assigned to slot 2")
	end)

	T.it("keeps center-only fixed letters out of hand-card slots", function()
		local j = {
			puzzle = { center = "L", min = 3, max = 7, kind = "span" },
			slots = {
				{ kind = "span", side = "before", cards = {}, min = 0, max = 7 },
				{ kind = "fixed", letter = "L" },
				{ kind = "span", side = "after", cards = {}, min = 0, max = 7 },
			},
		}
		local before = j.slots[1]
		local after = j.slots[3]
		local session = {
			area = { cards = {}, T = { x = 0, y = 0, w = 10, h = 2 } },
			ctx = { card_w = function() return 1 end, card_h = function() return 1.4 end },
		}
		G.GAME.word_round = { jumble = j }
		local jumble_model = require("word_game.model.jumble")
		T.assert_equal(jumble_model.blank_slot_index_for_x(session, 0), 1)
		before.cards = { {} }
		T.assert_equal(jumble_model.blank_slot_index_for_x(session, 0), 3)
		T.assert_equal(jumble.center_slot_index(j, 1), 2)
		T.assert_equal(#after.cards, 0)
	end)

	T.it("redirects a second center-only card to the other side", function()
		local j = {
			puzzle = { center = "L", min = 3, max = 7, kind = "span" },
			slots = {
				{ kind = "span", side = "before", cards = {}, min = 1, max = 7 },
				{ kind = "fixed", letter = "L" },
				{ kind = "span", side = "after", cards = {}, min = 1, max = 7 },
			},
		}
		G.GAME.word_round = { jumble = j }
		local jumble_model = require("word_game.model.jumble")
		local first, second = {}, {}
		T.assert_true(jumble_model.assign_card_to_blank(1, first))
		T.assert_true(jumble_model.assign_card_to_blank(1, second))
		T.assert_equal(#j.slots[1].cards, 1)
		T.assert_equal(#j.slots[3].cards, 1)
		T.assert_equal(j.slots[2].letter, "L")
	end)

	T.it("places cards around pinned center letter without overlapping fixed card", function()
		local jumble_model = require("word_game.model.jumble")
		local geo = require("word_game.board.jumble_geometry")
		local p = jumble_model.resolve_puzzle({ center = "L", pin_index = 2, min = 3, max = 7 })
		local wr = { mode = "jumble", jumble = {} }
		jumble_model.apply_puzzle(wr, p)
		G.GAME.word_round = wr

		local j = wr.jumble
		T.assert_equal(#j.slots, 3)
		T.assert_equal(j.slots[1].max, 1, "before max should be exactly 1 for pin_index 2")
		T.assert_equal(j.slots[3].max, 5, "after max should be 5 for pin_index 2 with max 7")

		local session = {
			area = {
				cards = {},
				T = { x = 0, y = 0, w = 10, h = 2 },
				hard_set_cards = function() end,
			},
			ctx = {
				card_w = function() return 1 end,
				card_h = function() return 1.4 end,
			},
		}

		local card1 = { T = { x = 0, y = 0, w = 1, h = 1.4, r = 0 }, states = { drag = {} } }
		local card2 = { T = { x = 0, y = 0, w = 1, h = 1.4, r = 0 }, states = { drag = {} } }
		local card3 = { T = { x = 0, y = 0, w = 1, h = 1.4, r = 0 }, states = { drag = {} } }

		T.assert_true(jumble_model.assign_card_to_blank(1, card1))
		T.assert_equal(#j.slots[1].cards, 1, "1st card should be in before slot (left)")
		T.assert_equal(#j.slots[3].cards, 0, "after slot should still be empty")

		T.assert_true(jumble_model.assign_card_to_blank(1, card2))
		T.assert_equal(#j.slots[1].cards, 1, "before slot should still have only 1 card")
		T.assert_equal(#j.slots[3].cards, 1, "2nd card should be placed in after slot (right)")

		T.assert_true(jumble_model.assign_card_to_blank(1, card3))
		T.assert_equal(#j.slots[1].cards, 1, "before slot should remain 1 card")
		T.assert_equal(#j.slots[3].cards, 2, "3rd card should be placed in after slot")

		geo.relayout(session)
		local active_len = jumble_model.span_active_len(j)
		T.assert_equal(active_len, 4, "Active length with 1 before + 1 center + 2 after should be 4")
		local centers = geo.span_centers(session, active_len)
		local card_w = session.ctx:card_w()

		T.assert_almost_equal(card1.T.x, centers[1] - card_w * 0.5, 0.001, "Card 1 should be at slot 1")
		local fixed_items = jumble_model.fixed_letter_items(j, active_len)
		T.assert_equal(fixed_items[1].pos, 2, "Fixed letter 'L' must be at slot 2")
		T.assert_almost_equal(card2.T.x, centers[3] - card_w * 0.5, 0.001, "Card 2 should be at slot 3 (right of L)")
		T.assert_almost_equal(card3.T.x, centers[4] - card_w * 0.5, 0.001, "Card 3 should be at slot 4 (right of card 2)")
	end)

	T.it("returns 'Must play a word or skip entirely' when blanks are not filled", function()
		local wr = {
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr
		local word, err = jumble.validate_current()
		T.assert_nil(word, "word should be nil when blanks unfilled")
		T.assert_equal(err, "Must play a word or skip entirely", "error message should match expected text")
	end)

	T.it("calculates active length and bounds correctly for multi-letter suffix like _ A R", function()
		local geo = require("word_game.board.jumble_geometry")
		local p_ar = jumble.resolve_puzzle({ suffix = "AR", min = 3, max = 7 })
		local wr = {
			mode = "jumble",
			jumble = {
				puzzle_index = 2,
				solved = false,
				puzzle = p_ar,
				slots = {
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", anchor = "suffix", letter = "AR" },
				},
			},
		}
		G.GAME.word_round = wr

		T.assert_equal(jumble.span_active_len(wr.jumble), 3, "Active length for _ AR with 0 cards is 3")

		table.insert(wr.jumble.slots[1].cards, { letter = "C", T = { x = 0, y = 0, w = 1, h = 1.4 }, states = { drag = {} } })
		T.assert_equal(jumble.span_active_len(wr.jumble), 3, "Active length for C + AR is 3")

		table.insert(wr.jumble.slots[1].cards, { letter = "T", T = { x = 0, y = 0, w = 1, h = 1.4 }, states = { drag = {} } })
		T.assert_equal(jumble.span_active_len(wr.jumble), 4, "Active length for ST + AR is 4")

		local session = {
			area = { T = { x = 0, y = 0, w = 10, h = 2 } },
			ctx = {
				card_w = function() return 1 end,
				card_h = function() return 1.4 end,
				tile_scale = function() return 20 end,
			},
		}
		local centers = geo.span_centers(session, 4)
		T.assert_equal(#centers, 4, "Should produce 4 slot centers for active length 4")

		local slot_i, insert_pos = jumble.blank_slot_index_for_x(session, centers[1] - 0.5)
		T.assert_equal(slot_i, 1, "Snaps to span slot 1")
		T.assert_equal(insert_pos, 1, "Inserts at start of span")

		local mid_x = (centers[1] + centers[2]) / 2
		slot_i, insert_pos = jumble.blank_slot_index_for_x(session, mid_x - 0.05)
		T.assert_equal(slot_i, 1, "Snaps to span slot 1")
		T.assert_equal(insert_pos, 1, "Inserts before second card")
	end)

	T.it("calculates alternating skew rotations with boundary priorities correctly", function()
		local skew = jumble.FIXED_LETTER_SKEW

		local j_ar = {
			puzzle = { suffix = "AR", min = 3, max = 7, kind = "span" },
			slots = {
				{ kind = "span", cards = {}, min = 1, max = 5 },
				{ kind = "fixed", anchor = "suffix", letter = "AR" },
			},
		}
		local rot_ar = jumble.fixed_letter_items(j_ar, 3)
		T.assert_equal(#rot_ar, 2, "2 fixed letters for _ A R")
		T.assert_equal(rot_ar[1].char, "A", "First fixed is A")
		T.assert_equal(rot_ar[1].position_label, "∞-1", "A is one position before the open-ended suffix")
		T.assert_almost_equal(rot_ar[1].rotation, -skew, 0.0001, "A is skewed to the left")
		T.assert_equal(rot_ar[2].char, "R", "Second fixed is R")
		T.assert_equal(rot_ar[2].position_label, "∞", "R is the open-ended final position")
		T.assert_almost_equal(rot_ar[2].rotation, skew, 0.0001, "R is skewed to the right")

		local j_str = {
			puzzle = { prefix = "S", center = "T", suffix = "R", min = 5, max = 7, kind = "span" },
			slots = {
				{ kind = "fixed", anchor = "prefix", letter = "S" },
				{ kind = "span", cards = {}, min = 1, max = 2 },
				{ kind = "fixed", anchor = "center", letter = "T" },
				{ kind = "span", cards = {}, min = 1, max = 2 },
				{ kind = "fixed", anchor = "suffix", letter = "R" },
			},
		}
		local rot_str = jumble.fixed_letter_items(j_str, 5)
		T.assert_equal(#rot_str, 3, "3 fixed letters for S _ T _ R")
		T.assert_equal(rot_str[1].char, "S")
		T.assert_equal(rot_str[1].position_label, "1", "Prefix S is in position 1")
		T.assert_almost_equal(rot_str[1].rotation, -skew, 0.0001, "S is skewed to the left (priority 1)")
		T.assert_equal(rot_str[2].char, "T")
		T.assert_equal(rot_str[2].position_label, "2", "Center T is in its resolved fixed position")
		T.assert_almost_equal(rot_str[2].rotation, skew, 0.0001, "T is skewed to the right (alternating)")
		T.assert_equal(rot_str[3].char, "R")
		T.assert_equal(rot_str[3].position_label, "∞", "Suffix R is open-ended")
		T.assert_almost_equal(rot_str[3].rotation, skew, 0.0001, "R is skewed to the right (priority 2)")

		local j_stir = {
			puzzle = { prefix = "S", center = "TI", suffix = "R", min = 6, max = 7, kind = "span" },
			slots = {
				{ kind = "fixed", anchor = "prefix", letter = "S" },
				{ kind = "span", cards = {}, min = 1, max = 2 },
				{ kind = "fixed", anchor = "center", letter = "TI" },
				{ kind = "span", cards = {}, min = 1, max = 2 },
				{ kind = "fixed", anchor = "suffix", letter = "R" },
			},
		}
		local rot_stir = jumble.fixed_letter_items(j_stir, 6)
		T.assert_equal(#rot_stir, 4, "4 fixed letters for S _ T _ I _ R")
		T.assert_equal(rot_stir[1].char, "S")
		T.assert_almost_equal(rot_stir[1].rotation, -skew, 0.0001, "S skewed left")
		T.assert_equal(rot_stir[2].char, "T")
		T.assert_almost_equal(rot_stir[2].rotation, skew, 0.0001, "T skewed right")
		T.assert_equal(rot_stir[3].char, "I")
		T.assert_almost_equal(rot_stir[3].rotation, -skew, 0.0001, "I skewed left")
		T.assert_equal(rot_stir[4].char, "R")
		T.assert_almost_equal(rot_stir[4].rotation, skew, 0.0001, "R skewed right")

		local j_ct = {
			puzzle = { span = { "C", "T" }, prefix = "C", suffix = "T", min = 3, max = 7, kind = "span" },
			slots = {
				{ kind = "fixed", anchor = "prefix", letter = "C" },
				{ kind = "span", cards = {}, min = 1, max = 5 },
				{ kind = "fixed", anchor = "suffix", letter = "T" },
			},
		}
		local rot_ct = jumble.fixed_letter_items(j_ct, 3)
		T.assert_equal(#rot_ct, 2)
		T.assert_almost_equal(rot_ct[1].rotation, -skew, 0.0001, "C skewed left")
		T.assert_almost_equal(rot_ct[2].rotation, skew, 0.0001, "T skewed right")

		local j_ate = {
			puzzle = { suffix = "ATE", min = 5, max = 7, kind = "span" },
			slots = {
				{ kind = "span", cards = {}, min = 1, max = 5 },
				{ kind = "fixed", anchor = "suffix", letter = "ATE" },
			},
		}
		local rot_ate = jumble.fixed_letter_items(j_ate, 5)
		T.assert_equal(#rot_ate, 3)
		T.assert_almost_equal(rot_ate[1].rotation, skew, 0.0001, "A in ATE skewed right")
		T.assert_almost_equal(rot_ate[2].rotation, -skew, 0.0001, "T in ATE skewed left")
		T.assert_almost_equal(rot_ate[3].rotation, skew, 0.0001, "E in ATE skewed right")

		local j_rigid = {
			slots = {
				{ kind = "blank", index = 1 },
				{ kind = "fixed", index = 2, letter = "E" },
				{ kind = "blank", index = 3 },
				{ kind = "fixed", index = 4, letter = "L" },
				{ kind = "blank", index = 5 },
			},
		}
		local rot_rigid = jumble.fixed_letter_items(j_rigid, 5)
		T.assert_equal(#rot_rigid, 2)
		T.assert_equal(rot_rigid[1].position_label, "2", "Rigid fixed letter shows its slot number")
		T.assert_almost_equal(rot_rigid[1].rotation, -skew, 0.0001, "E in _E_L_ skewed left")
		T.assert_almost_equal(rot_rigid[2].rotation, skew, 0.0001, "L in _E_L_ skewed right")
	end)

	T.it("anchors card area vertically consistently on initial load regardless of hand position state", function()
		local geo = require("word_game.board.jumble_geometry")
		local pcfg = require("word_game.board.config")
		local felt = { x = 0.8, y = 2.0, w = 15.4, h = 8.0 }
		local area_h = 1.33
		local pad_y = felt.h * pcfg.ANCHOR_PAD_Y_FRAC
		local expected_y = felt.y + pad_y

		local y_uninit = geo.anchor_y(felt, area_h, 0)
		T.assert_almost_equal(y_uninit, expected_y, 0.001, "anchor_y with uninit hand should equal felt.y + pad_y")

		local y_nil = geo.anchor_y(felt, area_h, nil)
		T.assert_almost_equal(y_nil, expected_y, 0.001, "anchor_y with nil hand should equal felt.y + pad_y")

		local y_positioned = geo.anchor_y(felt, area_h, 8.0)
		T.assert_almost_equal(y_positioned, expected_y, 0.001, "anchor_y with positioned hand should equal felt.y + pad_y")
	end)
end)
