--[[ tests/unit/test_bonus_cards.lua - Stage 1-4 bonus card rules and boss fly animation ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Bonus cards", function()
	mock_env.reset_game()
	local bonus_stack = require("word_game.ui.boss_word_stack")
	local jumble = require("word_game.model.jumble")

	local function layout_globals()
		G.GAME = G.GAME or {}
		G.GAME.word_round = { jumble = { boss_word_active = true } }
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.CARD_W = 2
		G.CARD_H = 2.8
		G.ROOM = { T = { x = 0, y = 0, w = 20, h = 11.5 } }
		G.hand = { T = { x = 3.2, y = 8.0, w = 10.5, h = 2.8 } }
		G.placement_table = {
			area = {
				T = { x = 0.6, y = 2.0, w = 18.0, h = 2.8 },
				hard_set_cards = function() end,
			},
			relayout = function() end,
		}
	end

	local function mock_card(letter, x, y)
		return {
			ability = { letter = letter, bonus = 0 },
			T = { x = x, y = y, w = 2, h = 2.8, r = 0 },
			VT = { x = x, y = y, w = 2, h = 2.8, r = 0 },
			states = { drag = { can = true, is = false }, collide = { can = true } },
			hard_set_T = function(self, nx, ny, nw, nh)
				self.T.x = nx or self.T.x
				self.T.y = ny or self.T.y
				self.T.w = nw or self.T.w
				self.T.h = nh or self.T.h
				self.VT.x, self.VT.y = self.T.x, self.T.y
			end,
			remove_from_area = function(self)
				self.area = nil
				self.parent = nil
			end,
			translate_container = function() end,
			draw = function() end,
		}
	end

	T.it("promotes boss word cards to one-time +10 bonus cards", function()
		bonus_stack.clear()
		local cards = { mock_card("C", 1, 1), mock_card("A", 1, 2), mock_card("T", 1, 3) }
		bonus_stack.promote_to_bonus(cards)
		T.assert_true(bonus_stack.is_active())
		T.assert_equal(#bonus_stack.cards(), 3)
		for _, card in ipairs(cards) do
			T.assert_true(card.bonus_card)
			T.assert_nil(card.boss_temp)
			T.assert_equal(card.ability.bonus, bonus_stack.BONUS_POINTS)
		end
	end)

	T.it("stages boss word cards on the left bonus stack column", function()
		bonus_stack.clear()
		layout_globals()
		local start_x = 10.0
		local cards = {
			mock_card("V", start_x, 5),
			mock_card("E", start_x + 1, 5),
		}
		bonus_stack.stage_cards(cards)
		T.assert_true(bonus_stack.is_animating())
		local target_x = select(1, bonus_stack.target_position(1))
		T.assert_true(target_x < start_x - 2, "Bonus stack should sit left of the placement row")
		for i, card in ipairs(cards) do
			local tx, ty = bonus_stack.target_position(i)
			card:hard_set_T(tx, ty, card.T.w, card.T.h)
			T.assert_almost_equal(card.T.x, target_x, 0.05)
			T.assert_true(card.T.y >= ty - 0.01)
		end
		bonus_stack.promote_to_bonus(cards)
		T.assert_false(bonus_stack.is_animating())
		T.assert_true(bonus_stack.is_active())
	end)

	T.it("present_boss_word_success stages cards and schedules the left-stack fly", function()
		bonus_stack.clear()
		layout_globals()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TimelineTimer = WORD_GAME.TimelineTimer or { pause = function() end }
		WORD_GAME.BossWordStack = bonus_stack

		local play_effects = require("word_game.ui.play_effects")
		local queued = 0
		local orig_stage = bonus_stack.stage_cards
		local orig_animate = bonus_stack.animate_cards_to_stack
		bonus_stack.stage_cards = function(cards)
			orig_stage(cards)
		end
		bonus_stack.animate_cards_to_stack = function(queue_event, easing_mod, opts)
			queued = queued + 1
			T.assert_not_nil(opts.on_complete)
			T.assert_equal(opts.initial_delay, 1.0)
			if opts.on_complete then
				opts.on_complete()
			end
		end

		local start_x = 9.5
		local used_cards = {
			mock_card("V", start_x, 4),
			mock_card("E", start_x + 1, 4),
			mock_card("G", start_x + 2, 4),
		}
		local cleared = false
		local j = {
			slots = {},
			puzzle = { boss_word = "VEGETABLE" },
		}
		G.GAME.word_round = { set = 1, hand_index = 3, jumble = j }

		play_effects.present_boss_word_success({
			clear_blank_cards = function() end,
			sync_placement_cards = function() end,
		}, j, used_cards, function()
			cleared = true
		end)

		T.assert_equal(queued, 1, "Boss success should schedule the fly-to-stack animation")
		T.assert_true(bonus_stack.is_active())
		T.assert_true(cleared)
		for _, card in ipairs(used_cards) do
			T.assert_true(card.bonus_card)
		end

		bonus_stack.stage_cards = orig_stage
		bonus_stack.animate_cards_to_stack = orig_animate
	end)

	T.it("detaches won cards from placement before flying them left", function()
		bonus_stack.clear()
		layout_globals()
		local area = {
			cards = {},
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						card.area = nil
						card.parent = nil
						return
					end
				end
			end,
		}
		G.placement_table.area = area
		G.placement_table.on_remove_card = function() end
		local cards = { mock_card("V", 9.5, 4), mock_card("E", 10.5, 4) }
		for _, card in ipairs(cards) do
			card.area = area
			card.parent = area
		end
		bonus_stack.stage_cards(cards)
		for _, card in ipairs(cards) do
			T.assert_nil(card.area, "Bonus cards must leave the placement area to draw on the left")
			T.assert_nil(card.parent)
		end
		local tx = select(1, bonus_stack.target_position(1))
		bonus_stack.animate_cards_to_stack(nil, nil, {})
		T.assert_almost_equal(cards[1].T.x, tx, 0.05)
		T.assert_true(cards[1].T.x < 9.5)
	end)

	T.it("insets the play column so bonus cards stay on-screen", function()
		bonus_stack.clear()
		layout_globals()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.BossWordStack = bonus_stack
		local felt = require("word_game.ui.layout.felt")
		local before = felt.play_column()
		bonus_stack.promote_to_bonus({ mock_card("A", 1, 1) })
		local after = felt.play_column()
		T.assert_true(after.x > before.x, "Play column should shift right to leave a bonus-card gutter")
		T.assert_true(after.w < before.w)
		local stack_x = select(1, bonus_stack.target_position(1))
		T.assert_true(stack_x + 2 <= after.x + 0.05, "Bonus stack should sit in the left gutter")
		bonus_stack.clear()
	end)

	T.it("destroys leftover boss cards instead of adding them to the deck", function()
		bonus_stack.clear()
		local kept = mock_card("V", 1, 1)
		local leftover = mock_card("X", 2, 2)
		leftover.boss_temp = true
		bonus_stack.promote_to_bonus({ kept })
		local destroyed = {}
		local orig_deck = package.loaded["word_game.model.cards.deck"]
		package.loaded["word_game.model.cards.deck"] = {
			destroy_card = function(card)
				destroyed[#destroyed + 1] = card
				card.REMOVED = true
			end,
		}
		bonus_stack.finalize_for_bonus_hand({
			jumble = { boss_cards = { kept, leftover } },
		})
		T.assert_equal(#destroyed, 1)
		T.assert_true(destroyed[1] == leftover)
		T.assert_true(bonus_stack.is_active())
		T.assert_true(kept.bonus_card)
		package.loaded["word_game.model.cards.deck"] = orig_deck
	end)

	T.it("keeps bonus cards on the left when stage 1-4 begins", function()
		bonus_stack.clear()
		layout_globals()
		local cards = { mock_card("Z", 1, 1) }
		bonus_stack.promote_to_bonus(cards)
		bonus_stack.on_hand_start(1, 4)
		T.assert_true(bonus_stack.is_active())
		T.assert_equal(#bonus_stack.cards(), 1)
		T.assert_true(bonus_stack.cards()[1].bonus_card)
		bonus_stack.on_hand_start(2, 1)
		T.assert_false(bonus_stack.is_active())
	end)

	T.it("adds +10 per bonus card used in puzzle scoring", function()
		local wr = {
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr
		local bonus = mock_card("A", 0, 0)
		bonus.bonus_card = true
		local _, new_pts = jumble.record_puzzle_word("CAT", { used_cards = { bonus } })
		T.assert_equal(new_pts, 3 + bonus_stack.BONUS_POINTS)
	end)

	T.it("excludes bonus cards from jumble deck population", function()
		mock_env.reset_game()
		local deck_mod = require("word_game.model.cards.deck")
		G.playing_cards = {
			{ REMOVED = false, boss_temp = false, bonus_card = false },
			{ REMOVED = false, bonus_card = true },
		}
		G.deck = {
			cards = {},
			config = { card_limit = 0 },
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			hard_set_T = function() end,
		}
		G.hand = { cards = {}, remove_card = function() end }
		G.placement_table = { area = { cards = {}, hard_set_cards = function() end } }
		deck_mod.populate_jumble_deck()
		T.assert_equal(#G.deck.cards, 1)
	end)

	T.it("persists promoted boss cards into stage 1-4", function()
		bonus_stack.clear()
		layout_globals()
		G.ARGS = G.ARGS or {}
		local round = require("word_game.model.round")
		local cards = {
			mock_card("V", 1, 1),
			mock_card("E", 2, 2),
			mock_card("G", 3, 3),
		}
		bonus_stack.promote_to_bonus(cards)
		round.start_hand(1, 4)
		T.assert_true(bonus_stack.is_active(), "Bonus cards should persist into stage 1-4")
		T.assert_equal(#bonus_stack.cards(), 3)
	end)
end)
