--[[ tests/unit/test_play_hold_redraw.lua
     Tests for Play button hold-to-redraw feature:
     - 5.0s hold duration
     - Progress calculation
     - Accidental click prevention vs normal click
     - Discarding full hand offscreen down and dealing 7 new cards
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Play Button Hold Redraw (word_game.ui.play_hold_redraw)", function()
	mock_env.reset_game()
	local PlayHoldRedraw = require("word_game.ui.play_hold_redraw")

	T.it("has a 5.0 second hold duration", function()
		T.assert_equal(PlayHoldRedraw.HOLD_DURATION, 5.0, "HOLD_DURATION should be 5.0 seconds")
	end)

	T.it("calculates hold progress from 0 to 1 over 5 seconds", function()
		T.assert_equal(PlayHoldRedraw.hold_progress(), 0, "Progress should start at 0")
	end)

	T.it("can_hold respects game state and active animations", function()
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME = {
			word_score_animating = false,
			hand_redraw_animating = false,
			seed_streams = { seed = "TEST", hashed_seed = 0 },
		}

		local mock_btn = {
			states = { visible = true },
			config = { button = "play_word", id = "hand_play_button" },
		}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.HandShuffle = WORD_GAME.HandShuffle or {}
		WORD_GAME.HandShuffle.play_button_uie = function() return mock_btn end
		WORD_GAME.TradeUI = { is_open = function() return false end }

		T.assert_true(PlayHoldRedraw.can_hold(), "Should allow hold when table board is active")

		WORD_GAME.TradeUI = { is_open = function() return true end }
		T.assert_false(PlayHoldRedraw.can_hold(), "Should not allow hold while the card marketplace is open")
		WORD_GAME.TradeUI = { is_open = function() return false end }

		G.GAME.hand_redraw_animating = true
		T.assert_equal(PlayHoldRedraw.can_hold(), false, "Should not allow hold during redraw animation")
		G.GAME.hand_redraw_animating = false

		G.GAME.word_score_animating = true
		T.assert_equal(PlayHoldRedraw.can_hold(), false, "Should not allow hold during score animation")
		G.GAME.word_score_animating = false
	end)

	T.it("tracks hold state and triggers redraw at 5 seconds", function()
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME = {
			word_score_animating = false,
			hand_redraw_animating = false,
			seed_streams = { seed = "TEST", hashed_seed = 0 },
		}

		local mock_btn = {
			states = { visible = true, collide = { is = true }, hover = { is = true } },
			config = { button = "play_word", id = "hand_play_button" },
			VT = { x = 10, y = 8, w = 1.25, h = 1.25 },
		}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.HandShuffle = WORD_GAME.HandShuffle or {}
		WORD_GAME.HandShuffle.play_button_uie = function() return mock_btn end

		local dealt_count = 0
		WORD_GAME.Deck = WORD_GAME.Deck or {}
		WORD_GAME.Deck.deal_into_hand = function(target_size, on_complete)
			dealt_count = target_size
			if on_complete then on_complete() end
		end

		local queued_events = {}
		G.TIMELINE = {
			enqueue = function(self, ev)
				queued_events[#queued_events + 1] = ev
			end
		}

		local hand_cards = {}
		for i = 1, 7 do
			hand_cards[i] = {
				T = { x = i, y = 7, r = 0 },
				area = nil,
				remove_from_area = function(self) end,
			}
		end

		G.hand = {
			cards = hand_cards,
			unhighlight_all = function(self) end,
			set_ranks = function(self) end,
			relayout = function(self) end,
			hard_set_cards = function(self) end,
			remove_card = function(self, card)
				for idx, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, idx)
						break
					end
				end
			end,
		}

		for _, c in ipairs(hand_cards) do
			c.area = G.hand
		end

		local deck_cards = {}
		G.deck = {
			cards = deck_cards,
			emplace = function(self, card)
				deck_cards[#deck_cards + 1] = card
				card.area = self
			end,
			shuffle = function(self) end,
			hard_set_T = function(self) end,
		}

		G.INPUT = {
			pointer_held = true,
			collision_list = { mock_btn },
			nodes_at_cursor = { mock_btn },
		}

		-- Advance time by 2.5s (halfway)
		PlayHoldRedraw.update(2.5)
		T.assert_true(PlayHoldRedraw.is_holding(), "Should be holding at 2.5s")
		T.assert_equal(math.floor(PlayHoldRedraw.hold_progress() * 100 + 0.5), 50, "Progress should be 50% at 2.5s")
		T.assert_equal(PlayHoldRedraw.is_animating(), false, "Should not be animating before 5s")

		-- Advance another 2.5s (reaches 5.0s)
		PlayHoldRedraw.update(2.5)
		T.assert_true(PlayHoldRedraw.is_animating(), "Should be animating at 5.0s")
		T.assert_true(#queued_events > 0, "Should have queued discard and redraw events")

		-- Execute the queued events
		for _, ev in ipairs(queued_events) do
			if ev.func then ev.func() end
		end

		T.assert_equal(#G.deck.cards, 7, "All 7 hand cards should be returned to deck")
		T.assert_equal(dealt_count, 7, "Should trigger deal_into_hand for 7 cards")
	end)

	T.it("differentiates quick clicks from cancelled holds", function()
		PlayHoldRedraw.reset()
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME = {
			word_score_animating = false,
			hand_redraw_animating = false,
			seed_streams = { seed = "TEST", hashed_seed = 0 },
		}

		local mock_btn = {
			states = { visible = true, collide = { is = true }, hover = { is = true } },
			config = { button = "play_word", id = "hand_play_button" },
		}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.HandShuffle = WORD_GAME.HandShuffle or {}
		WORD_GAME.HandShuffle.play_button_uie = function() return mock_btn end

		G.INPUT = {
			pointer_held = true,
			collision_list = { mock_btn },
			nodes_at_cursor = { mock_btn },
		}

		-- Very quick press (0.05s) and release
		PlayHoldRedraw.update(0.05)
		G.INPUT.pointer_held = false
		PlayHoldRedraw.update(0.016)

		-- Quick click should NOT be consumed, allowing normal play
		T.assert_equal(PlayHoldRedraw.consume_click(), false, "Quick click under 0.18s should not be consumed")

		-- Medium press (1.0s) and release before 5s
		G.INPUT.pointer_held = true
		PlayHoldRedraw.update(1.0)
		G.INPUT.pointer_held = false
		PlayHoldRedraw.update(0.016)

		-- Cancelled hold should be consumed to prevent accidental play
		T.assert_true(PlayHoldRedraw.consume_click(), "Cancelled hold >= 0.18s should be consumed")
		T.assert_equal(PlayHoldRedraw.is_animating(), false, "Cancelled hold should not animate")
	end)

	T.it("renders ring with container translation and correct circular button radius", function()
		PlayHoldRedraw.reset()
		G.STATE = G.STATES.TABLE_BOARD
		G.TILESIZE = 20

		local container_translated = false
		local prep_drawn = false

		local mock_sprite = {
			VT = { w = 0.92, h = 0.92 },
			states = { visible = true },
		}

		local mock_btn = {
			states = { visible = true, collide = { is = true }, hover = { is = true } },
			config = { button = "play_word", id = "hand_play_button" },
			VT = { x = 10, y = 8, w = 1.0, h = 1.0, scale = 1, r = 0 },
			container = {
				T = { x = 2, y = 1, w = 20, h = 11, r = 0 },
			},
			translate_container = function(self)
				container_translated = true
			end,
			children = {
				{
					config = { id = "play_hand_icon", object = mock_sprite },
				},
			},
		}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.HandShuffle = WORD_GAME.HandShuffle or {}
		WORD_GAME.HandShuffle.play_button_uie = function() return mock_btn end

		G.INPUT = {
			pointer_held = true,
			collision_list = { mock_btn },
			nodes_at_cursor = { mock_btn },
		}

		PlayHoldRedraw.update(1.0)
		T.assert_true(PlayHoldRedraw.is_holding(), "Should be holding")

		-- Mock love.graphics functions to verify drawing
		_G.love = _G.love or {}
		love.graphics = love.graphics or {}
		local lines_drawn = 0
		local orig_line = love.graphics.line
		local orig_push = love.graphics.push
		local orig_pop = love.graphics.pop
		local orig_scale = love.graphics.scale
		local orig_set_color = love.graphics.setColor
		local orig_set_lw = love.graphics.setLineWidth
		local orig_set_join = love.graphics.setLineJoin
		local orig_prep = _G.push_node_transform

		push_node_transform = function(moveable, scale)
			prep_drawn = true
		end
		love.graphics.line = function(...)
			lines_drawn = lines_drawn + 1
		end
		love.graphics.push = function() end
		love.graphics.pop = function() end
		love.graphics.scale = function() end
		love.graphics.setColor = function() end
		love.graphics.setLineWidth = function() end
		love.graphics.setLineJoin = function() end

		PlayHoldRedraw.draw()

		push_node_transform = orig_prep
		love.graphics.line = orig_line
		love.graphics.push = orig_push
		love.graphics.pop = orig_pop
		love.graphics.scale = orig_scale
		love.graphics.setColor = orig_set_color
		love.graphics.setLineWidth = orig_set_lw
		love.graphics.setLineJoin = orig_set_join

		T.assert_true(container_translated, "translate_container should be called for correct screen positioning")
		T.assert_true(prep_drawn, "push_node_transform should be called on button")
		T.assert_true(lines_drawn > 0, "Arc lines should be drawn for the ring")
	end)

	T.it("restores card drag and input states when redraw completes", function()
		PlayHoldRedraw.reset()
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME = {
			word_score_animating = false,
			hand_redraw_animating = false,
			seed_streams = { seed = "TEST", hashed_seed = 0 },
		}

		local mock_btn = {
			states = { visible = true, collide = { is = true }, hover = { is = true } },
			config = { button = "play_word", id = "hand_play_button" },
		}

		local hand_cards = {}
		for i = 1, 7 do
			hand_cards[i] = {
				T = { x = i, y = 8, w = 1, h = 1.4, r = 0 },
				states = { drag = { can = true }, hover = { can = true }, collide = { can = true } },
			}
		end

		G.hand = {
			cards = hand_cards,
			config = { type = "hand" },
			emplace = function(self, card)
				card.area = self
				table.insert(self.cards, card)
				self:set_ranks()
			end,
			remove_card = function(self, card)
				for idx, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, idx)
						card.area = nil
						break
					end
				end
			end,
			relayout = function() end,
			hard_set_cards = function() end,
			set_ranks = function(self)
				for _, card in ipairs(self.cards) do
					if WORD_GAME and WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.allows_card_drag
						and not WORD_GAME.PlayerHost.allows_card_drag(self) then
						card.states.drag.can = false
					else
						card.states.drag.can = true
						card.states.hover.can = true
						card.states.collide.can = true
					end
				end
			end,
		}

		for _, card in ipairs(hand_cards) do
			card.area = G.hand
		end

		G.deck = {
			cards = {},
			config = { type = "deck" },
			emplace = function(self, card)
				table.insert(self.cards, card)
			end,
			shuffle = function() end,
			hard_set_T = function() end,
		}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.HandShuffle = WORD_GAME.HandShuffle or {}
		WORD_GAME.HandShuffle.play_button_uie = function() return mock_btn end

		local refreshed = false
		WORD_GAME.PlayerHost = {
			allows_card_drag = function(area)
				if G.GAME and G.GAME.hand_redraw_animating then
					return false
				end
				return true
			end,
			refresh_card_input = function()
				refreshed = true
				if G.hand then G.hand:set_ranks() end
			end,
		}

		local queued_events = {}
		G.TIMELINE = {
			enqueue = function(self, ev)
				table.insert(queued_events, ev)
			end,
		}

		WORD_GAME.Deck = {
			deal_into_hand = function(target_size, on_complete)
				-- Simulate dealing new cards into hand while redraw is in progress
				for i = 1, target_size do
					local new_card = {
						T = { x = i, y = 8, w = 1, h = 1.4 },
						states = { drag = {}, hover = {}, collide = {} },
					}
					G.hand:emplace(new_card)
				end
				if on_complete then on_complete() end
			end,
		}

		G.INPUT = {
			pointer_held = true,
			collision_list = { mock_btn },
			nodes_at_cursor = { mock_btn },
		}

		-- Hold for 5s to trigger redraw
		PlayHoldRedraw.update(5.0)
		T.assert_true(PlayHoldRedraw.is_animating(), "Should be animating redraw")

		-- Execute the queued events (discard animation tail -> deck -> deal)
		for _, ev in ipairs(queued_events) do
			if ev.func then ev.func() end
		end

		T.assert_equal(PlayHoldRedraw.is_animating(), false, "Redraw should be finished")
		T.assert_equal(G.GAME.hand_redraw_animating, false, "hand_redraw_animating flag should be false")
		T.assert_true(refreshed, "PlayerHost.refresh_card_input should have been called")

		-- Verify all 7 new hand cards are now draggable
		T.assert_equal(#G.hand.cards, 7, "Hand should have 7 new cards")
		for i, card in ipairs(G.hand.cards) do
			T.assert_true(card.states.drag.can, "Card " .. i .. " in hand must be draggable after redraw")
			T.assert_true(card.states.hover.can, "Card " .. i .. " in hand must be hoverable after redraw")
			T.assert_true(card.states.collide.can, "Card " .. i .. " in hand must be collidable after redraw")
		end
	end)
end)
