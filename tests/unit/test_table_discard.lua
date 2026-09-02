--[[ tests/unit/test_table_discard.lua - Vault discard bin ]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

T.describe("table discard bin", function()
	T.it("vault HUD places discard row below deck count without stamp debug buttons", function()
		MockEnv.setup()
		G.GAME = G.GAME or {}
		G.GAME.deck_left_count = 7
		G.GAME.word_round = { mode = "jumble" }
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.TILE_H = 11.5
		G.TILE_W = 20
		G.ROOM = { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
		G.ROOM_ATTACH = { T = { x = 0, y = 0, w = G.TILE_W, h = G.TILE_H } }
		G.VAULT_ATTACH = { T = { x = 17, y = 0.22, w = 3, h = 10 } }

		local hud_definition = require("word_game.ui.sidebar.hud_definition")
		local def = hud_definition.hud_definition()
		local function find_id(node, id)
			if not node then return nil end
			if node.config and node.config.id == id then return node end
			for _, child in ipairs(node.nodes or {}) do
				local found = find_id(child, id)
				if found then return found end
			end
			for _, child in pairs(node.nodes or {}) do
				if type(child) == "table" then
					local found = find_id(child, id)
					if found then return found end
				end
			end
			return nil
		end

		T.assert_not_nil(find_id(def, "row_discard"), "discard row should exist")
		T.assert_not_nil(find_id(def, "row_discards_left"), "discards left row should exist below the bin")
		T.assert_not_nil(find_id(def, "discards_left_odometer"), "discards left should use an odometer")
		T.assert_nil(find_id(def, "row_perk_stamp_play"), "stamp play debug row should be removed")
		T.assert_nil(find_id(def, "row_perk_stamp"), "stamp frame debug row should be removed")
		MockEnv.reset_game()
	end)

	T.it("counts discards left down from 3 to 0 with odometer rolls", function()
		local table_discard = require("word_game.ui.table_discard")
		table_discard.reset()
		T.assert_equal(table_discard.discards_left(), 3)

		local rolls = {}
		G.VAULT_HUD = {
			find_node_by_id = function(_, id)
				if id ~= "discards_left_odometer" then return nil end
				return {
					config = {
						object = {
							display_count = 3,
							start_roll = function(self, from, to)
								rolls[#rolls + 1] = { from = from, to = to }
								self.display_count = from
							end,
						},
					},
				}
			end,
		}

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.discards_left(), 2)
		T.assert_equal(rolls[#rolls].from, 3)
		T.assert_equal(rolls[#rolls].to, 2)

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.discards_left(), 1)
		T.assert_equal(rolls[#rolls].from, 2)
		T.assert_equal(rolls[#rolls].to, 1)

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.discards_left(), 0)
		T.assert_equal(rolls[#rolls].from, 1)
		T.assert_equal(rolls[#rolls].to, 0)
		T.assert_true(table_discard.should_show_end_run())

		G.VAULT_HUD = nil
	end)

	T.it("starts on the empty top-left sprite and advances through the 2x2 sheet", function()
		local table_discard = require("word_game.ui.table_discard")
		table_discard.reset()

		T.assert_equal(table_discard.sprite_frame(), 0, "empty bin uses frame 0")
		local col, row = table_discard.sprite_cell(0)
		T.assert_equal(col, 0, "frame 0 should be top-left column")
		T.assert_equal(row, 0, "frame 0 should be top-left row")

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.sprite_frame(), 1)
		col, row = table_discard.sprite_cell(1)
		T.assert_equal(col, 1, "frame 1 should be top-right")
		T.assert_equal(row, 0)

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.sprite_frame(), 2)
		col, row = table_discard.sprite_cell(2)
		T.assert_equal(col, 0, "frame 2 should be bottom-left")
		T.assert_equal(row, 1)

		T.assert_true(table_discard.record_discard())
		T.assert_true(table_discard.should_show_end_run(), "third discard should swap bin for End Run")
		T.assert_equal(table_discard.sprite_frame(), 0, "bin sprite should not show the full frame once End Run is active")

		T.assert_false(table_discard.record_discard(), "fourth discard should be rejected")
		T.assert_true(table_discard.is_full())
		T.assert_true(table_discard.should_show_end_run(), "sprite stays replaced by End Run")

		table_discard.reset()
		T.assert_false(table_discard.should_show_end_run())
		T.assert_equal(table_discard.sprite_frame(), 0, "reset returns to empty bin")
		T.assert_false(table_discard.is_full())
	end)

	T.it("offers End Run instead of the full bin sprite after three discards", function()
		local table_discard = require("word_game.ui.table_discard")
		table_discard.reset()
		table_discard.record_discard()
		table_discard.record_discard()
		T.assert_false(table_discard.should_show_end_run())
		table_discard.record_discard()
		T.assert_true(table_discard.should_show_end_run())
		T.assert_false(table_discard.uses_table_draw() and not table_discard.should_show_end_run(), "bin draw should be off once full")
	end)

	T.it("end_run triggers game over when the bin is full", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.table_discard")
		G.STATES.GAME_OVER = 4
		table_discard.reset()
		for _ = 1, 3 do
			table_discard.record_discard()
		end
		G.GAME = G.GAME or {}
		G.GAME.alpha = { match_over = false, match_won = false }
		G.GAME.word_score_animating = false
		G.GAME.hand_redraw_animating = false
		G.GAME.hand_shuffle_animating = false
		G.GAME.placement_recall_animating = false
		G.RUN = { active = true }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.PlayHoldRedraw = { is_animating = function() return false end }
		G.STATE = G.STATES.TABLE_BOARD
		G.STATE_COMPLETE = true
		T.assert_true(table_discard.end_run())
		T.assert_equal(G.STATE, G.STATES.GAME_OVER)
		T.assert_equal(G.GAME.alpha.match_over, true)
		T.assert_equal(G.GAME.alpha.match_won, false)
		T.assert_equal(G.STATE_COMPLETE, false)
		MockEnv.reset_game()
	end)

	T.it("sprite viewport covers one sheet cell, not the full atlas", function()
		local table_discard = require("word_game.ui.table_discard")
		G.TEXTURE_ATLASES = G.TEXTURE_ATLASES or {}
		G.TEXTURE_ATLASES.bin = {
			cols = 2,
			rows = 2,
			image = { getDimensions = function() return 498, 501 end },
		}
		local qx, qy, qw, qh, iw, ih = table_discard.sprite_viewport(0)
		T.assert_almost_equal(qw, iw / 2, 0.01, "cell width should be half the atlas")
		T.assert_almost_equal(qh, ih / 2, 0.01, "cell height should be half the atlas")
		T.assert_equal(qx, 0)
		T.assert_equal(qy, 0)
		local qx1, qy1 = table_discard.sprite_viewport(1)
		T.assert_almost_equal(qx1, iw / 2, 0.01, "frame 1 should be the top-right cell")
		T.assert_equal(qy1, 0)
	end)

	T.it("does not render discarded hand cards on top of the sidebar bin sprite", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.table_discard")
		local deck = require("word_game.model.cards.deck")
		local discard_layer = require("word_game.ui.cardarea.discard")
		table_discard.reset()

		G.STATE = G.STATES.TABLE_BOARD
		G.TIMELINE = nil
		G.GAME = {
			word_round = { mode = "jumble" },
			word_score_animating = false,
			hand_redraw_animating = false,
			round_scores = { cards_discarded = { amt = 0 } },
		}
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.discard = {
			config = { type = "discard" },
			T = { x = 17.5, y = 9.2, w = 0.58, h = 0.81 },
			cards = {},
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						return card
					end
				end
			end,
			relayout = function() end,
			hard_set_cards = function() end,
		}
		G.deck = {
			cards = { { id = "new" } },
			remove_card = function(self) return table.remove(self.cards) end,
		}
		G.hand = {
			cards = {},
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						return card
					end
				end
			end,
			set_ranks = function() end,
			relayout = function() end,
			hard_set_cards = function() end,
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = { is_active = function() return true end }
		WORD_GAME.TableDiscard = table_discard
		WORD_GAME.Deck = deck
		WORD_GAME.HandShuffle = { sync = function() end }

		local card = {
			area = G.hand,
			T = { x = 17.6, y = 9.3, w = 1, h = 1.4 },
			VT = { x = 17.6, y = 9.3, w = 1, h = 1.4 },
			states = { visible = true },
		}
		G.hand.cards[1] = card

		local orig_replacement = deck.draw_jumble_replacement
		deck.draw_jumble_replacement = function() return { id = "new" } end

		T.assert_true(table_discard.try_discard(card), "drag-to-bin should discard")
		T.assert_equal(#G.discard.cards, 1, "discarded card should live in the discard pile for reshuffle")

		local stashed = G.discard.cards[1]
		T.assert_true(stashed.bin_stash, "bin discards should be stashed")
		T.assert_equal(stashed.states.visible, false, "stashed bin cards should not render")
		T.assert_false(table_discard.is_pile_card_visible(stashed, G.discard),
			"sidebar bin mode should never draw discard pile cards")

		-- Legacy bug: misaligned VT used to trigger pile draw over the bin sprite.
		stashed.VT = { x = G.discard.T.x + 1.0, y = G.discard.T.y, w = 1, h = 1.4 }
		T.assert_false(table_discard.is_pile_card_visible(stashed, G.discard),
			"VT offset must not resurrect pile card draw in sidebar bin mode")

		local pile_draws = 0
		G.ARGS = G.ARGS or {}
		G.ARGS.table_discard_board_draw = true
		discard_layer.draw_layer(G.discard, "card", function()
			pile_draws = pile_draws + 1
		end)
		G.ARGS.table_discard_board_draw = false
		T.assert_equal(pile_draws, 0, "discard draw layer should only paint the bin sprite, not pile cards")

		deck.draw_jumble_replacement = orig_replacement
		MockEnv.reset_game()
	end)

	T.it("discards a hand card, updates the bin sprite, and deals a replacement", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.table_discard")
		local deck = require("word_game.model.cards.deck")
		table_discard.reset()

		G.STATE = G.STATES.TABLE_BOARD
		G.TIMELINE = nil
		G.GAME = {
			word_round = { mode = "jumble" },
			word_score_animating = false,
			hand_redraw_animating = false,
			round_scores = { cards_discarded = { amt = 0 } },
		}
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.discard = {
			T = { x = 17.5, y = 9.2, w = 0.58, h = 0.81 },
			cards = {},
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						return card
					end
				end
			end,
			relayout = function() end,
			hard_set_cards = function() end,
		}
		G.deck = {
			cards = { { id = "new" } },
			remove_card = function(self) return table.remove(self.cards) end,
		}
		G.hand = {
			cards = {},
			emplace = function(self, card)
				self.cards[#self.cards + 1] = card
				card.area = self
			end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						return card
					end
				end
			end,
			set_ranks = function() end,
			relayout = function() end,
			hard_set_cards = function() end,
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = { is_active = function() return true end }
		WORD_GAME.TableDiscard = table_discard
		WORD_GAME.Deck = deck
		WORD_GAME.HandShuffle = { sync = function() end }

		local card = {
			area = G.hand,
			T = { x = 17.6, y = 9.3, w = 1, h = 1.4 },
		}
		G.hand.cards[1] = card

		local replaced = false
		local orig_replacement = deck.draw_jumble_replacement
		deck.draw_jumble_replacement = function()
			replaced = true
			return { id = "new" }
		end

		T.assert_equal(table_discard.sprite_frame(), 0)
		T.assert_true(table_discard.try_discard(card), "drop on bin should discard")
		T.assert_true(replaced, "discard should deal a replacement")
		T.assert_equal(table_discard.sprite_frame(), 1, "bin sprite should advance after discard")

		deck.draw_jumble_replacement = orig_replacement
		MockEnv.reset_game()
	end)

	T.it("blocks discards once the bin is full", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.table_discard")
		local deck = require("word_game.model.cards.deck")
		table_discard.reset()

		for _ = 1, table_discard.MAX_FILLS do
			T.assert_true(table_discard.record_discard())
		end
		T.assert_true(table_discard.is_full())

		G.STATE = G.STATES.TABLE_BOARD
		G.TIMELINE = nil
		G.GAME = {
			word_round = { mode = "jumble" },
			word_score_animating = false,
			hand_redraw_animating = false,
		}
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.discard = { T = { x = 17.5, y = 9.2, w = 0.58, h = 0.81 }, cards = {} }
		G.hand = { cards = {} }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TableDiscard = table_discard
		WORD_GAME.Deck = deck

		local card = {
			area = G.hand,
			T = { x = 17.6, y = 9.3, w = 1, h = 1.4 },
		}
		G.hand.cards[1] = card

		T.assert_false(table_discard.can_discard_card(card), "full bin should block drag discard")
		T.assert_false(table_discard.try_discard(card), "full bin should reject drop")
		T.assert_false(deck.discard_from_hand(card), "full bin should reject model discard")

		MockEnv.reset_game()
	end)

	T.it("resets the bin sprite when a fresh jumble hand is dealt", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.table_discard")
		local deck = require("word_game.model.cards.deck")
		table_discard.reset()
		table_discard.record_discard()
		table_discard.record_discard()
		T.assert_equal(table_discard.sprite_frame(), 2)

		G.hand = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.deck = {
			cards = { {}, {} },
			remove_card = function(self) return table.remove(self.cards) end,
		}
		G.GAME = { word_round = { mode = "jumble" } }
		G.placement_table = { area = { cards = {}, hard_set_cards = function() end } }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.TableDiscard = table_discard
		WORD_GAME.Jumble = { ensure_playable_puzzle = function() end }

		deck.deal_jumble_hand()
		T.assert_equal(table_discard.sprite_frame(), 0, "new hand should clear the bin sprite")

		MockEnv.reset_game()
	end)
end)
