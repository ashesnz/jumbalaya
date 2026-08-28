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
		G.ROOM = { T = { x = 1, y = 0, w = 20, h = 11.5 } }
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
			set_card_area = function(self, area)
				self.area = area
			end,
			translate_container = function() end,
			draw = function() end,
		}
	end

	local function mock_hand()
		return {
			T = { x = 3.2, y = 8.0, w = 10.5, h = 2.8 },
			cards = {},
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			remove_card = function(self, card)
				for i, held in ipairs(self.cards) do
					if held == card then
						table.remove(self.cards, i)
						if card.remove_from_area then
							card:remove_from_area()
						end
						return card
					end
				end
			end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
	end

	local function mock_jumble(slots)
		G.GAME = G.GAME or {}
		G.GAME.word_round = G.GAME.word_round or {}
		G.GAME.word_round.jumble = {
			slots = slots,
			puzzle = { min = 3, max = 7 },
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function() return G.GAME.word_round.jumble end,
			slot_for_card = jumble.slot_for_card,
			remove_card_from_blanks = jumble.remove_card_from_blanks,
			assign_card_to_blank = jumble.assign_card_to_blank,
			sync_placement_cards = jumble.sync_placement_cards,
			build_word = jumble.build_word,
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
		local window_left = -(G.ROOM.T.x or 0)
		T.assert_almost_equal(target_x, window_left + bonus_stack.LEFT_WINDOW_MARGIN, 0.02)
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
			T.assert_equal(opts.initial_delay, 0)
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

	T.it("parks bonus cards against the left window with a small margin", function()
		bonus_stack.clear()
		layout_globals()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.BossWordStack = bonus_stack
		local felt = require("word_game.ui.layout.felt")
		local before = felt.play_column()
		local hand_col = felt.hand_play_column()
		bonus_stack.promote_to_bonus({ mock_card("A", 8, 4) })
		local after = felt.play_column()
		T.assert_almost_equal(after.x, before.x, 0.001)
		T.assert_almost_equal(after.w, before.w, 0.001)
		T.assert_almost_equal(felt.hand_play_column().x, hand_col.x, 0.001)
		local stack_x = select(1, bonus_stack.target_position(1))
		local window_left = -(G.ROOM.T.x or 0)
		T.assert_almost_equal(stack_x, window_left + bonus_stack.LEFT_WINDOW_MARGIN, 0.02)
		T.assert_true(stack_x > window_left, "Small margin should keep cards off the hard left")
		T.assert_true(stack_x + G.CARD_W < G.hand.T.x, "Stack should sit away from the dealt hand")
		bonus_stack.clear()
	end)

	T.it("does not move placement or hand bounds while bonus cards fly left", function()
		bonus_stack.clear()
		layout_globals()
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TimelineTimer = WORD_GAME.TimelineTimer or { pause = function() end }
		WORD_GAME.BossWordStack = bonus_stack
		local felt = require("word_game.ui.layout.felt")
		local play_effects = require("word_game.ui.play_effects")

		WORD_GAME.Layout = {
			update_all = function()
				G.hand.T.x = G.hand.T.x + 2
				G.placement_table.area.T.x = G.placement_table.area.T.x + 2
			end,
			set_screen_positions = function()
				G.hand.T.x = G.hand.T.x + 2
				G.placement_table.area.T.x = G.placement_table.area.T.x + 2
			end,
		}
		G.hand.relayout = function(self)
			self.T.x = self.T.x + 2
		end
		G.placement_table.relayout = function()
			G.placement_table.area.T.x = G.placement_table.area.T.x + 2
		end

		local j = {
			slots = {},
			puzzle = { boss_word = "VEGETABLE" },
			boss_word_active = true,
		}
		G.GAME.word_round = { set = 1, hand_index = 3, jumble = j }

		WORD_GAME.Layout = {
			update_all = function()
				G.hand.T.x = G.hand.T.x + 2
				G.placement_table.area.T.x = G.placement_table.area.T.x + 2
			end,
			set_screen_positions = function()
				G.hand.T.x = G.hand.T.x + 2
				G.placement_table.area.T.x = G.placement_table.area.T.x + 2
			end,
		}
		G.hand.relayout = function(self)
			self.T.x = self.T.x + 2
		end
		G.placement_table.relayout = function()
			G.placement_table.area.T.x = G.placement_table.area.T.x + 2
		end

		local hand_before = {
			x = G.hand.T.x, y = G.hand.T.y, w = G.hand.T.w, h = G.hand.T.h,
		}
		local area_before = {
			x = G.placement_table.area.T.x,
			y = G.placement_table.area.T.y,
			w = G.placement_table.area.T.w,
			h = G.placement_table.area.T.h,
		}
		local col_before = felt.play_column()
		local hand_col_before = felt.hand_play_column()

		local orig_animate = bonus_stack.animate_cards_to_stack
		bonus_stack.animate_cards_to_stack = function()
			T.assert_true(bonus_stack.is_animating())
			T.assert_almost_equal(G.hand.T.x, hand_before.x, 0.001)
			T.assert_almost_equal(G.hand.T.y, hand_before.y, 0.001)
			T.assert_almost_equal(G.hand.T.w, hand_before.w, 0.001)
			T.assert_almost_equal(G.hand.T.h, hand_before.h, 0.001)
			T.assert_almost_equal(G.placement_table.area.T.x, area_before.x, 0.001)
			T.assert_almost_equal(G.placement_table.area.T.y, area_before.y, 0.001)
			T.assert_almost_equal(G.placement_table.area.T.w, area_before.w, 0.001)
			T.assert_almost_equal(G.placement_table.area.T.h, area_before.h, 0.001)
			T.assert_almost_equal(felt.play_column().x, col_before.x, 0.001)
			T.assert_almost_equal(felt.play_column().w, col_before.w, 0.001)
			T.assert_almost_equal(felt.hand_play_column().x, hand_col_before.x, 0.001)
			T.assert_almost_equal(felt.hand_play_column().w, hand_col_before.w, 0.001)
		end

		play_effects.present_boss_word_success({
			clear_blank_cards = function() end,
			sync_placement_cards = function() end,
		}, j, { mock_card("V", 9.5, 4), mock_card("E", 10.5, 4) })

		T.assert_almost_equal(G.hand.T.x, hand_before.x, 0.001)
		T.assert_almost_equal(G.hand.T.y, hand_before.y, 0.001)
		T.assert_almost_equal(G.hand.T.w, hand_before.w, 0.001)
		T.assert_almost_equal(G.hand.T.h, hand_before.h, 0.001)
		T.assert_almost_equal(G.placement_table.area.T.x, area_before.x, 0.001)
		T.assert_almost_equal(G.placement_table.area.T.y, area_before.y, 0.001)
		T.assert_almost_equal(G.placement_table.area.T.w, area_before.w, 0.001)
		T.assert_almost_equal(G.placement_table.area.T.h, area_before.h, 0.001)
		T.assert_almost_equal(felt.play_column().x, col_before.x, 0.001)
		T.assert_almost_equal(felt.play_column().w, col_before.w, 0.001)

		bonus_stack.animate_cards_to_stack = orig_animate
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

	T.it("keeps bonus cards on the left through stages 1-4, 1-5, and 1-6", function()
		bonus_stack.clear()
		layout_globals()
		local cards = { mock_card("Z", 1, 1) }
		bonus_stack.promote_to_bonus(cards)
		for hand = 4, 6 do
			bonus_stack.on_hand_start(1, hand)
			T.assert_true(bonus_stack.is_active(), "Bonus stack should persist on 1-" .. hand)
			T.assert_equal(#bonus_stack.cards(), 1)
			T.assert_true(bonus_stack.cards()[1].bonus_card)
		end
		bonus_stack.on_hand_start(1, 7)
		T.assert_false(bonus_stack.is_active(), "Bonus stack clears when stage 1-7 begins")
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

	T.it("lifts the left gutter stack by about 20 pixels", function()
		bonus_stack.clear()
		layout_globals()
		G.TILESIZE = 20
		G.TILESCALE = 73 / 20
		local placement = require("word_game.ui.layout.placement")
		local timer = placement.timeline_rect()
		local layout = bonus_stack.stack_layout()
		local margin_y = math.max(0.10, G.CARD_H * 0.08)
		local lift = bonus_stack.stack_y_lift()
		T.assert_almost_equal(lift * G.TILESIZE * G.TILESCALE, bonus_stack.STACK_Y_LIFT_PX, 0.6)
		T.assert_almost_equal(layout.y, timer.y + timer.h + margin_y - lift, 0.02)
		T.assert_true(layout.y < timer.y + timer.h + margin_y - 0.01)
	end)

	T.it("remove_card_from_blanks clears a bonus slot", function()
		layout_globals()
		local card = mock_card("B", 1, 1)
		local slots = { { kind = "blank", card = card } }
		mock_jumble(slots)
		jumble.remove_card_from_blanks(card)
		T.assert_nil(slots[1].card)
	end)

	T.it("returns a placement bonus card to the left gutter when dropped there", function()
		bonus_stack.clear()
		layout_globals()
		G.hand = mock_hand()
		local snap = require("word_game.board.snap")
		local card = mock_card("B", 5, 2.4)
		bonus_stack.promote_to_bonus({ card })
		local slots = { { kind = "blank", card = card } }
		mock_jumble(slots)
		card.area = G.placement_table.area
		G.placement_table.area.cards = { card }
		G.placement_table.area.remove_card = function(self, c)
			for i, held in ipairs(self.cards) do
				if held == c then
					table.remove(self.cards, i)
					c.area = nil
					return
				end
			end
		end
		local gutter_x, gutter_y = bonus_stack.target_position(1)
		card.T.x, card.T.y = gutter_x, gutter_y
		local cx = card.T.x + card.T.w / 2
		T.assert_true(cx < G.placement_table.area.T.x, "test drop should be left of the placement row")
		snap.try_snap({
			area = G.placement_table.area,
			ctx = {
				card_w = function() return G.CARD_W end,
				card_h = function() return G.CARD_H end,
			},
		}, card)
		T.assert_nil(slots[1].card, "Bonus card should leave the placement row")
		T.assert_true(bonus_stack.contains(card), "Bonus card should return to the gutter")
		T.assert_nil(card.area)
		T.assert_equal(#G.hand.cards, 0)
		bonus_stack.clear()
	end)

	T.it("returns a placement bonus card to its slot when dropped below the row", function()
		bonus_stack.clear()
		layout_globals()
		G.hand = mock_hand()
		local snap = require("word_game.board.snap")
		local card = mock_card("B", 5, 2.4)
		bonus_stack.promote_to_bonus({ card })
		local slots = { { kind = "blank", card = card } }
		mock_jumble(slots)
		card.area = G.placement_table.area
		G.placement_table.area.cards = { card }
		G.placement_table.area.remove_card = function(self, c)
			for i, held in ipairs(self.cards) do
				if held == c then
					table.remove(self.cards, i)
					c.area = nil
					return
				end
			end
		end
		card.T.x, card.T.y = 5, 7
		snap.try_snap({
			area = G.placement_table.area,
			ctx = {
				card_w = function() return G.CARD_W end,
				card_h = function() return G.CARD_H end,
			},
		}, card)
		T.assert_equal(slots[1].card, card, "Bonus card should return to its placement slot")
		T.assert_equal(card.area, G.placement_table.area)
		T.assert_equal(#G.hand.cards, 0)
		bonus_stack.clear()
	end)

	T.it("rejects a gutter bonus card dropped on the dealt hand", function()
		bonus_stack.clear()
		layout_globals()
		G.hand = mock_hand()
		local snap = require("word_game.board.snap")
		local card = mock_card("B", 5, 8.5)
		bonus_stack.promote_to_bonus({ card })
		mock_jumble({})
		snap.try_snap({
			area = G.placement_table.area,
			ctx = {
				card_w = function() return G.CARD_W end,
				card_h = function() return G.CARD_H end,
			},
		}, card)
		T.assert_true(bonus_stack.contains(card), "Gutter bonus should return to the gutter")
		T.assert_nil(card.area)
		T.assert_equal(#G.hand.cards, 0, "Bonus cards must not enter the dealt hand")
		bonus_stack.clear()
	end)

	T.it("restores a placement bonus card dropped on the dealt hand", function()
		bonus_stack.clear()
		layout_globals()
		G.hand = mock_hand()
		local snap = require("word_game.board.snap")
		local card = mock_card("B", 5, 2.4)
		bonus_stack.promote_to_bonus({ card })
		local slots = { { kind = "blank", card = card } }
		mock_jumble(slots)
		card.area = G.placement_table.area
		G.placement_table.area.cards = { card }
		G.placement_table.area.remove_card = function(self, c)
			for i, held in ipairs(self.cards) do
				if held == c then
					table.remove(self.cards, i)
					c.area = nil
					return
				end
			end
		end
		card.T.x, card.T.y = 5, 8.5
		snap.try_snap({
			area = G.placement_table.area,
			ctx = {
				card_w = function() return G.CARD_W end,
				card_h = function() return G.CARD_H end,
			},
		}, card)
		T.assert_equal(slots[1].card, card, "Bonus card should return to its placement slot")
		T.assert_equal(card.area, G.placement_table.area)
		T.assert_equal(#G.hand.cards, 0)
		bonus_stack.clear()
	end)

	T.it("sync_positions ejects bonus cards that end up in the dealt hand", function()
		bonus_stack.clear()
		layout_globals()
		G.hand = mock_hand()
		local card = mock_card("B", 5, 8.5)
		bonus_stack.promote_to_bonus({ card })
		G.hand:emplace(card)
		T.assert_equal(#G.hand.cards, 1)
		bonus_stack.sync_positions()
		T.assert_equal(#G.hand.cards, 0)
		T.assert_true(bonus_stack.contains(card))
		T.assert_nil(card.area)
		bonus_stack.clear()
	end)

	T.it("sends gutter cards back to the gutter when recalling the placement row", function()
		bonus_stack.clear()
		layout_globals()
		local hand_shuffle = require("word_game.ui.hand_shuffle")
		local bonus = mock_card("G", 4, 2)
		local dealt = mock_card("H", 6, 2)
		bonus_stack.promote_to_bonus({ bonus })
		bonus.area = G.placement_table.area
		dealt.area = G.placement_table.area
		G.placement_table.area.cards = { bonus, dealt }
		G.placement_table.area.remove_card = function(self, card)
			for i, held in ipairs(self.cards) do
				if held == card then
					table.remove(self.cards, i)
					card.area = nil
					return
				end
			end
		end
		G.placement_table.on_remove_card = function() end
		G.hand = {
			cards = {},
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			clear_selection = function() end,
			set_ranks = function() end,
			relayout = function() end,
			hard_set_cards = function() end,
			snap_VT = function() end,
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = { is_active = function() return false end }
		hand_shuffle.recall_placement_cards()
		T.assert_true(bonus_stack.contains(bonus), "Gutter card should return to the gutter")
		T.assert_nil(bonus.area)
		T.assert_equal(#G.hand.cards, 1)
		T.assert_equal(G.hand.cards[1], dealt)
		bonus_stack.clear()
	end)

	T.it("dissolves a bonus card when it is consumed after a play", function()
		bonus_stack.clear()
		local card = mock_card("Z", 3, 3)
		local dissolved = false
		card.start_dissolve = function()
			dissolved = true
		end
		bonus_stack.promote_to_bonus({ card })
		bonus_stack.consume_card(card)
		T.assert_true(dissolved, "Played bonus cards should dissolve")
		T.assert_false(bonus_stack.is_active())
	end)

	T.it("spawns steam +10 flyover text above played bonus cards", function()
		bonus_stack.clear()
		layout_globals()
		local card = mock_card("Q", 4, 3)
		card.bonus_card = true
		local spawned = {}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.FloatUpText = {
			from_card = function(target, text, opts)
				spawned[#spawned + 1] = { card = target, text = text, opts = opts }
			end,
		}
		local play_effects = require("word_game.ui.play_effects")
		play_effects.show_bonus_flyovers({ card, mock_card("A", 0, 0) })
		T.assert_equal(#spawned, 1)
		T.assert_equal(spawned[1].card, card)
		T.assert_equal(spawned[1].text, "+" .. tostring(bonus_stack.BONUS_POINTS))
		WORD_GAME.FloatUpText = nil
	end)
end)
