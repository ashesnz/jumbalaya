--[[ tests/unit/test_stage3_boss_words.lua - Stage 1-3 boss puzzle rules ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Stage 1-3 boss words", function()
	T.it("defines nine-letter boss words", function()
		local config = require("word_game.config.jumble_puzzles.1_3")
		T.assert_equal(#config.BOSS_WORDS, 9)
		for _, word in ipairs(config.BOSS_WORDS) do
			T.assert_equal(#word, 9, "Every boss word should have nine letters")
		end
	end)

	T.it("generates a nine-letter puzzle with two revealed letters", function()
		local jumble = require("word_game.model.jumble")
		local puzzle = jumble.boss_puzzle(1, 3)
		T.assert_not_nil(puzzle)
		local revealed = 0
		for i = 1, #puzzle.pattern do
			if puzzle.pattern:sub(i, i) ~= "_" then revealed = revealed + 1 end
		end
		T.assert_equal(#puzzle.pattern, 9)
		T.assert_equal(revealed, 2)
	end)

	T.it("leaves seven blank card slots", function()
		local jumble = require("word_game.model.jumble")
		local puzzle = jumble.boss_puzzle(1, 3)
		T.assert_equal(jumble.blank_count(jumble.parse_slots(puzzle), puzzle), 7)
	end)

	T.it("builds a shuffled hand from unrevealed boss letters", function()
		local jumble = require("word_game.model.jumble")
		local puzzle = jumble.boss_puzzle(1, 3)
		local letters = jumble.boss_hand_letters(puzzle.boss_word, puzzle.pattern)
		T.assert_equal(#letters, 7)
		local counts = {}
		for i = 1, #puzzle.boss_word do
			if puzzle.pattern:sub(i, i) == "_" then
				local ch = puzzle.boss_word:sub(i, i)
				counts[ch] = (counts[ch] or 0) + 1
			end
		end
		local hand_counts = {}
		for _, ch in ipairs(letters) do
			hand_counts[ch] = (hand_counts[ch] or 0) + 1
		end
		for ch, n in pairs(counts) do
			T.assert_equal(hand_counts[ch] or 0, n, "Boss hand should include each hidden letter")
		end
	end)

	T.it("keeps normal spacing for seven-letter and shorter rigid puzzles", function()
		local jumble = require("word_game.model.jumble")
		local geo = require("word_game.board.jumble_geometry")
		local config = require("word_game.board.config")
		local puzzle = { kind = "rigid", pattern = "_______" }
		local slots = jumble.parse_slots(puzzle)
		G.GAME = G.GAME or {}
		G.GAME.word_round = { mode = "jumble", jumble = { puzzle = puzzle, slots = slots } }
		G.TABLE_HAND_SIZE = 7
		G.CARD_W = 2
		G.HAND_CARD_SPACING = 0.78
		local ctx = {
			card_w = function() return G.CARD_W end,
			card_h = function() return G.CARD_H or 2.8 end,
		}
		local area_w = geo.area_width(ctx)
		local session = {
			ctx = ctx,
			area = { T = { x = 5, y = 2, w = area_w, h = 2.8 } },
		}
		local centers = geo.slot_centers(session)
		local expected_w = geo.group_width(G.CARD_W, 7, 0.78)
		T.assert_equal(area_w, G.CARD_W * config.row_width_for_slots(7))
		T.assert_equal(#centers, 7)
		T.assert_almost_equal(centers[7] - centers[1], expected_w - G.CARD_W, 0.01)
	end)

	T.it("uses a narrower placement boundary for three-letter rigid puzzles", function()
		local jumble = require("word_game.model.jumble")
		local geo = require("word_game.board.jumble_geometry")
		local config = require("word_game.board.config")
		local puzzle = { kind = "rigid", pattern = "C_T" }
		local slots = jumble.parse_slots(puzzle)
		G.GAME = G.GAME or {}
		G.GAME.word_round = { mode = "jumble", jumble = { puzzle = puzzle, slots = slots } }
		G.TABLE_HAND_SIZE = 7
		G.CARD_W = 2
		G.HAND_CARD_SPACING = 0.78
		local ctx = {
			card_w = function() return G.CARD_W end,
			card_h = function() return G.CARD_H or 2.8 end,
		}
		local area_w = geo.area_width(ctx)
		local session = {
			ctx = ctx,
			area = { T = { x = 5, y = 2, w = area_w, h = 2.8 } },
		}
		local centers = geo.slot_centers(session)
		local expected_w = geo.group_width(G.CARD_W, 3, 0.78)
		T.assert_equal(area_w, G.CARD_W * config.row_width_for_slots(3))
		T.assert_true(area_w < G.CARD_W * config.row_width_for_slots(7))
		T.assert_equal(#centers, 3)
		T.assert_almost_equal(centers[3] - centers[1], expected_w - G.CARD_W, 0.01)
	end)

	T.it("spaces nine boss slots without overlapping card widths", function()
		local jumble = require("word_game.model.jumble")
		local geo = require("word_game.board.jumble_geometry")
		local board_config = require("word_game.board.config")
		local puzzle = jumble.boss_puzzle(1, 3)
		local slots = jumble.parse_slots(puzzle)
		G.GAME = G.GAME or {}
		G.GAME.word_round = {
			mode = "jumble",
			jumble = {
				puzzle = puzzle,
				slots = slots,
				boss_word_active = true,
			},
		}
		G.TABLE_HAND_SIZE = 7
		G.CARD_W = 2
		G.HAND_CARD_SPACING = 0.78
		G.TILE_W = 20
		G.TILE_H = 11.5
		_G.get_table_felt_rect = function()
			return { x = 0.5, y = 2, w = 18, h = 7 }
		end
		local ctx = {
			card_w = function() return G.CARD_W end,
			card_h = function() return G.CARD_H or 2.8 end,
		}
		local felt_w = _G.get_table_felt_rect().w
		local area_w = geo.area_width(ctx)
		T.assert_true(area_w <= felt_w + 0.01, "Boss row should fit inside the felt width")
		local spacing = geo.boss_slot_spacing()
		local session = {
			ctx = ctx,
			area = { T = { x = 0.5, y = 2, w = area_w, h = 2.8 } },
		}
		local centers = geo.slot_centers(session)
		T.assert_equal(#centers, 9)
		local min_step = G.CARD_W * spacing * 0.85
		for i = 2, #centers do
			T.assert_true(
				centers[i] - centers[i - 1] >= min_step - 0.02,
				"Boss slots should stay separated"
			)
		end
		local seven_w = G.CARD_W * board_config.row_width_for_slots(7)
		T.assert_true(
			area_w > seven_w,
			"Boss row should be wider than a seven-card row when slots do not touch"
		)
	end)

	T.it("uses the full window width for boss play column layout", function()
		local felt = require("word_game.ui.layout.felt")
		G.GAME = {
			word_round = {
				jumble = { boss_word_active = true },
			},
		}
		G.TILE_W = 20
		G.ROOM = { T = { x = 0, y = 0, w = 20, h = 11.5 } }
		local boss_col = felt.play_column()
		G.GAME.word_round.jumble.boss_word_active = false
		local normal_col = felt.play_column()
		T.assert_true(boss_col.w > normal_col.w, "Boss layout should widen the play column")
	end)

	T.it("keeps hand felt on the normal play column during boss sequence", function()
		local felt = require("word_game.ui.layout.felt")
		G.GAME = {
			word_round = {
				jumble = { boss_word_active = true },
			},
		}
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.ROOM = { T = { x = 0, y = 0, w = 20, h = 11.5 } }
		local boss_col = felt.play_column()
		local hand_col = felt.hand_play_column()
		G.GAME.word_round.jumble.boss_word_active = false
		local normal_col = felt.play_column()
		T.assert_almost_equal(hand_col.x, normal_col.x, 0.01)
		T.assert_almost_equal(hand_col.w, normal_col.w, 0.01)
		T.assert_true(boss_col.w > hand_col.w, "Hand column should stay narrow while boss widens placement")
	end)

	T.it("stacks boss word cards below the timer with half-card overlap", function()
		local layout = require("word_game.ui.layout.placement")
		local boss_word_stack = require("word_game.ui.boss_word_stack")
		G.GAME = {
			word_round = {
				jumble = { boss_word_active = true },
			},
		}
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.CARD_W = 2
		G.CARD_H = 2.8
		G.ROOM = { T = { x = 1, y = 0, w = 20, h = 11.5 } }
		G.hand = { T = { x = 3.2, y = 8.0, w = 10.5, h = 2.8 } }
		G.placement_table = { area = { T = { x = 4.0, y = 2.0, w = 10.0, h = 2.8 } } }
		local stack = boss_word_stack.stack_layout()
		local timer = layout.timeline_rect()
		local window_left = -(G.ROOM.T.x or 0)
		T.assert_true(stack.y >= timer.y + timer.h - boss_word_stack.stack_y_lift() - 0.02,
			"Stack should sit just below the timer, lifted slightly")
		T.assert_almost_equal(stack.x, window_left + boss_word_stack.LEFT_WINDOW_MARGIN, 0.02)
		T.assert_true(stack.x > window_left, "Small margin should keep cards off the hard left")
		T.assert_true(
			stack.x + stack.card_w < G.hand.T.x,
			"Stack should not overlap the dealt hand"
		)
		T.assert_almost_equal(stack.step_y, stack.card_h * 0.5, 0.001)
		local x1, y1 = boss_word_stack.target_position(1)
		local x2, y2 = boss_word_stack.target_position(2)
		T.assert_almost_equal(x1, stack.x, 0.001)
		T.assert_almost_equal(y1, stack.y, 0.001)
		T.assert_almost_equal(x2, stack.x, 0.001)
		T.assert_almost_equal(y2, stack.y + stack.step_y, 0.001)
	end)

	T.it("accepts a filled nine-letter boss word even when it is absent from the dictionary", function()
		local jumble = require("word_game.model.jumble")
		Dictionary.load()
		T.assert_false(Dictionary.is_valid("VEGETABLE"), "Nine-letter boss words are outside the normal dictionary length cap")

		local puzzle = {
			kind = "rigid",
			pattern = "___E__B__",
			boss_word = "VEGETABLE",
			display = "___E__B__",
		}
		local slots = jumble.parse_slots(puzzle)
		local function card(letter)
			return { ability = { letter = letter } }
		end
		slots[1].card = card("V")
		slots[2].card = card("E")
		slots[3].card = card("G")
		slots[5].card = card("T")
		slots[6].card = card("A")
		slots[8].card = card("L")
		slots[9].card = card("E")

		G.GAME = G.GAME or {}
		G.GAME.word_round = {
			mode = "jumble",
			played_words = {},
			jumble = {
				boss_word_active = true,
				puzzle = puzzle,
				slots = slots,
			},
		}

		T.assert_equal(jumble.build_word(slots), "VEGETABLE")
		T.assert_true(jumble.word_fits_pattern("VEGETABLE", puzzle))
		local word, err = jumble.validate_current()
		T.assert_equal(word, "VEGETABLE", "validation error: " .. tostring(err))
		T.assert_nil(err)
	end)

	T.it("re-enables hand drag after boss deal set_ranks during word_score_animating", function()
		mock_env.reset_game()
		local InputLock = require("word_game.model.input_lock")
		local play_effects = require("word_game.ui.play_effects")

		G.GAME = {
			word_score_animating = true,
			hand_redraw_animating = false,
			hand_shuffle_animating = false,
			placement_recall_animating = false,
		}
		G.GAME.word_round = {
			mode = "jumble",
			jumble = { boss_word_active = true, boss_puzzle_hidden = false },
		}

		local hand_card = {
			ability = { letter = "A", set = "Default" },
			T = { x = 5, y = 8, w = 2, h = 2.8 },
			VT = { x = 5, y = 8, w = 2, h = 2.8 },
			states = { drag = { can = true, is = false }, collide = { can = true } },
			selected = false,
			set_card_area = function(self, area) self.area = area end,
			remove_from_area = function(self) self.area = nil end,
		}

		G.hand = {
			cards = { hand_card },
			T = { x = 3, y = 8, w = 10, h = 2.8 },
			config = { type = "hand" },
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						card.area = nil
						return card
					end
				end
			end,
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
			set_ranks = function(self)
				for _, card in ipairs(self.cards) do
					if InputLock.is_table_busy() then
						card.states.drag.can = false
					else
						card.states.drag.can = true
					end
				end
			end,
		}
		hand_card.area = G.hand

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.PlayerHost = {
			refresh_card_input = function()
				if G.hand then G.hand:set_ranks() end
			end,
		}
		WORD_GAME.PlayHoldRedraw = WORD_GAME.PlayHoldRedraw or { is_animating = function() return false end }

		-- Mirrors deal_boss_hand finish while countdown animation is still running.
		G.hand:set_ranks()
		T.assert_false(hand_card.states.drag.can, "set_ranks during score animation must block drag")

		play_effects.set_word_score_animating(false)
		T.assert_true(hand_card.states.drag.can, "Clearing score animation must restore hand drag")
	end)

	T.it("places a hand card into a boss word blank slot", function()
		mock_env.reset_game()
		local jumble = require("word_game.model.jumble")
		local snap = require("word_game.board.snap")
		local geo = require("word_game.board.jumble_geometry")
		local puzzle = jumble.boss_puzzle(1, 3)
		local slots = jumble.parse_slots(puzzle)

		G.GAME = G.GAME or {}
		G.GAME.word_round = {
			mode = "jumble",
			jumble = {
				boss_word_active = true,
				boss_puzzle_hidden = false,
				puzzle = puzzle,
				slots = slots,
			},
		}
		G.TABLE_HAND_SIZE = 7
		G.CARD_W = 2
		G.CARD_H = 2.8
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.hand = {
			cards = {},
			T = { x = 3, y = 8.5, w = 10, h = 2.8 },
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						card.area = nil
						return card
					end
				end
			end,
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}

		local placement_area = {
			cards = {},
			T = { x = 0.5, y = 5, w = 18, h = 2.8 },
			hard_set_cards = function() end,
			relayout = function() end,
		}
		local session = {
			area = placement_area,
			card_shimmer_t = {},
			jumble_geometry = geo,
			relayout = function() end,
			ctx = {
				card_w = function() return G.CARD_W end,
				card_h = function() return G.CARD_H end,
			},
		}
		G.placement_table = session

		local blank_i = nil
		for i, slot in ipairs(slots) do
			if slot.kind == "blank" then
				blank_i = i
				break
			end
		end
		T.assert_not_nil(blank_i, "Boss puzzle should have blank slots")

		placement_area.T.w = geo.area_width(session.ctx)
		local centers = geo.slot_centers(session)
		local cx = centers[slots[blank_i].index]
		T.assert_not_nil(cx, "Boss blank should have a slot center")

		local card = {
			ability = { letter = "Z", set = "Default" },
			T = { x = cx - G.CARD_W / 2, y = 5, w = G.CARD_W, h = G.CARD_H },
			VT = { x = cx - G.CARD_W / 2, y = 5, w = G.CARD_W, h = G.CARD_H },
			states = { drag = { can = true, is = false }, collide = { can = true } },
			selected = false,
			set_card_area = function(self, area) self.area = area end,
			remove_from_area = function(self) self.area = nil end,
		}
		G.hand.cards[#G.hand.cards + 1] = card
		card.area = G.hand

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = jumble
		WORD_GAME.HandShuffle = { try_sync = function() end }

		local placed = snap.place_in_row(session, card)
		T.assert_true(placed, "Boss hand card should snap into a blank slot")
		T.assert_equal(slots[blank_i].card, card, "Blank slot should hold the placed card")
		T.assert_equal(card.area, placement_area, "Card should belong to placement area")
	end)
end)