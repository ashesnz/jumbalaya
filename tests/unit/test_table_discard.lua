--[[ tests/unit/test_table_discard.lua - Sidebar voucher discard ]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")
local perk_cfg = require("word_game.config.perks")

local function discard_bin_entry()
	return perk_cfg.by_id("discard_bin")
end

local function discard_bin_imprint()
	return { perk = discard_bin_entry() }
end

local function setup_unlocked_voucher_discard()
	G.GAME = G.GAME or {}
	G.GAME.run_state = { perks = { "discard_bin" } }
	G.RUN = { active = true }
	G.STATE = G.STATES.TABLE_BOARD
	G.STAGE = G.STAGES.RUN
	G.TILESCALE = 1
	G.TILESIZE = 71
	G.ROOM = G.ROOM or { T = { x = 0, y = 0, w = 20, h = 11.5, r = 0 } }
	G.TEXTURE_ATLASES = G.TEXTURE_ATLASES or {}
	G.TEXTURE_ATLASES.Perk = {
		image = { getDimensions = function() return 911, 284 end },
	}
end

local function mock_discard_voucher(rect)
	rect = rect or { x = 170, y = 90, w = 80, h = 40 }
	WORD_GAME = WORD_GAME or {}
	WORD_GAME.PerkStamp = {
		current_imprints = function()
			return { discard_bin_imprint() }
		end,
		imprint_cell_rects_px = function()
			return { rect }
		end,
	}
end

local function card_over_voucher(rect)
	rect = rect or { x = 170, y = 90, w = 80, h = 40 }
	return {
		area = G.hand,
		T = {
			x = (rect.x + rect.w * 0.5) / ((G.TILESCALE or 1) * (G.TILESIZE or 1)) - 0.5,
			y = (rect.y + rect.h * 0.5) / ((G.TILESCALE or 1) * (G.TILESIZE or 1)) - 0.7,
			w = 1,
			h = 1.4,
		},
	}
end

T.describe("table discard bin", function()
	T.it("sidebar HUD places End Run below deck count without stamp debug buttons", function()
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
		G.SIDEBAR_ATTACH = { T = { x = 17, y = 0.22, w = 3, h = 10 } }

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

		T.assert_not_nil(find_id(def, "row_end_run"), "End Run row should exist")
		T.assert_not_nil(find_id(def, "end_run_button"), "End Run button should occupy the discard slot")
		T.assert_nil(find_id(def, "row_discards_left"), "discard counter overlays the voucher")
		T.assert_nil(find_id(def, "row_perk_stamp_play"), "stamp play debug row should be removed")
		T.assert_nil(find_id(def, "row_perk_stamp"), "stamp frame debug row should be removed")
		MockEnv.reset_game()
	end)

	T.it("counts discards left down from 2 to 0 with odometer rolls when voucher discard is unlocked", function()
		local table_discard = require("word_game.ui.perks.discard_bin")
		table_discard.reset()
		G.GAME = { run_state = { perks = { "discard_bin" } } }
		G.RUN = { active = true }
		T.assert_equal(table_discard.discards_left(), 2)

		local rolls = {}
		local odometer = table_discard.overlay_odometer()
		odometer.start_roll = function(self, from, to)
			rolls[#rolls + 1] = { from = from, to = to }
			self.display_count = from
		end

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.discards_left(), 1)
		T.assert_equal(rolls[#rolls].from, 2)
		T.assert_equal(rolls[#rolls].to, 1)

		T.assert_true(table_discard.record_discard())
		T.assert_equal(table_discard.discards_left(), 0)
		T.assert_equal(rolls[#rolls].from, 1)
		T.assert_equal(rolls[#rolls].to, 0)

		G.STATE = G.STATES.TABLE_BOARD
		T.assert_true(table_discard.should_show_end_run(), "End Run visible when discards are exhausted")

		G.GAME = nil
	end)

	T.it("rejects discards once the voucher allowance is used up", function()
		local table_discard = require("word_game.ui.perks.discard_bin")
		G.GAME = { run_state = { perks = { "discard_bin" } } }
		G.RUN = { active = true }
		G.STATE = G.STATES.TABLE_BOARD
		table_discard.reset()
		mock_discard_voucher()

		T.assert_true(table_discard.record_discard())
		T.assert_true(table_discard.record_discard())
		T.assert_false(table_discard.record_discard(), "third discard should be rejected")
		T.assert_true(table_discard.is_full())
		T.assert_false(table_discard.voucher_discard_active())
		T.assert_true(table_discard.should_show_end_run())

		table_discard.reset()
		T.assert_false(table_discard.is_full())
	end)

	T.it("shows End Run on the table board while voucher discard is disabled", function()
		local table_discard = require("word_game.ui.perks.discard_bin")
		table_discard.reset()
		G.GAME = { run_state = { perks = {} } }
		G.RUN = { active = true }
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		T.assert_true(table_discard.end_run_button_visible(), "End Run button should always show on table board")
		T.assert_true(table_discard.should_show_end_run(), "End Run action should be available on table board")
		table_discard.record_discard()
		T.assert_true(table_discard.end_run_button_visible(), "discards do not hide End Run while voucher discard is disabled")
		T.assert_true(table_discard.should_show_end_run(), "discards do not block End Run while voucher discard is disabled")
	end)

	T.it("end_run triggers game over from the sidebar button", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		G.STATES.GAME_OVER = 4
		table_discard.reset()
		G.GAME = G.GAME or {}
		G.GAME.run_state = { match_over = false, match_won = false }
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
		T.assert_equal(G.GAME.run_state.match_over, true)
		T.assert_equal(G.GAME.run_state.match_won, false)
		T.assert_equal(G.STATE_COMPLETE, false)
		MockEnv.reset_game()
	end)

	T.it("accepts drops on the discard_bin voucher imprint", function()
		local table_discard = require("word_game.ui.perks.discard_bin")
		local rect = { x = 170, y = 90, w = 80, h = 40 }
		G.GAME = { run_state = { perks = { "discard_bin" } } }
		G.RUN = { active = true }
		G.STATE = G.STATES.TABLE_BOARD
		G.TILESCALE = 1
		G.TILESIZE = 1
		table_discard.reset()
		mock_discard_voucher(rect)

		local card = card_over_voucher(rect)
		T.assert_true(table_discard.point_in_discard_voucher(
			card.T.x + card.T.w * 0.5,
			card.T.y + card.T.h * 0.5
		))
	end)

	T.it("blocks drag-to-voucher discards while the feature is disabled", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		local deck = require("word_game.model.cards.deck")
		table_discard.reset()

		G.STATE = G.STATES.TABLE_BOARD
		G.TIMELINE = nil
		G.TILESCALE = 1
		G.TILESIZE = 1
		G.GAME = {
			word_round = { mode = "jumble" },
			word_score_animating = false,
			hand_redraw_animating = false,
		}
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.hand = { cards = {} }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.VoucherDiscard = table_discard
		WORD_GAME.Deck = deck
		mock_discard_voucher()

		local card = card_over_voucher()
		G.hand.cards[1] = card

		T.assert_false(table_discard.can_discard_card(card), "voucher discard disabled should block drag discard")
		T.assert_false(table_discard.try_discard(card), "voucher discard disabled should reject drop")

		MockEnv.reset_game()
	end)

	T.it("discards a hand card dropped on the voucher and deals a replacement", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		local deck = require("word_game.model.cards.deck")
		G.GAME = { run_state = { perks = { "discard_bin" } }, word_round = { mode = "jumble" } }
		G.RUN = { active = true }
		table_discard.reset()

		G.STATE = G.STATES.TABLE_BOARD
		G.TIMELINE = nil
		G.TILESCALE = 1
		G.TILESIZE = 1
		G.GAME.word_score_animating = false
		G.GAME.hand_redraw_animating = false
		G.GAME.round_scores = { cards_discarded = { amt = 0 } }
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.discard = {
			T = { x = 17.5, y = 9.2, w = 0.58, h = 0.81 },
			cards = {},
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
		WORD_GAME.VoucherDiscard = table_discard
		WORD_GAME.Deck = deck
		WORD_GAME.HandShuffle = { sync = function() end }
		mock_discard_voucher()

		local card = card_over_voucher()
		G.hand.cards[1] = card

		local replaced = false
		local orig_replacement = deck.draw_jumble_replacement
		deck.draw_jumble_replacement = function()
			replaced = true
			return { id = "new" }
		end

		T.assert_equal(table_discard.discards_left(), 2)
		local rolls = {}
		local odometer = table_discard.overlay_odometer()
		odometer.start_roll = function(self, from, to)
			rolls[#rolls + 1] = { from = from, to = to }
			self.display_count = from
		end

		T.assert_true(table_discard.try_discard(card), "drop on voucher should discard")
		T.assert_true(replaced, "discard should deal a replacement")
		T.assert_equal(table_discard.discards_left(), 1)
		T.assert_equal(rolls[#rolls].from, 2)
		T.assert_equal(rolls[#rolls].to, 1)

		deck.draw_jumble_replacement = orig_replacement
		MockEnv.reset_game()
	end)

	T.it("blocks discards while the voucher feature is disabled", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		local deck = require("word_game.model.cards.deck")
		table_discard.reset()

		G.STATE = G.STATES.TABLE_BOARD
		G.TIMELINE = nil
		G.TILESCALE = 1
		G.TILESIZE = 1
		G.GAME = {
			word_round = { mode = "jumble" },
			word_score_animating = false,
			hand_redraw_animating = false,
		}
		G.CARD_W = 1
		G.CARD_H = 1.4
		G.hand = { cards = {} }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.VoucherDiscard = table_discard
		WORD_GAME.Deck = deck
		mock_discard_voucher()

		local card = card_over_voucher()
		G.hand.cards[1] = card

		T.assert_false(table_discard.can_discard_card(card), "voucher discard disabled should block drag discard")
		T.assert_false(table_discard.try_discard(card), "voucher discard disabled should reject drop")
		T.assert_false(deck.discard_from_hand(card), "voucher discard disabled should reject model discard")

		MockEnv.reset_game()
	end)

	T.it("resets voucher discards when a fresh jumble hand is dealt", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		local deck = require("word_game.model.cards.deck")
		G.GAME = { run_state = { perks = { "discard_bin" } }, word_round = { mode = "jumble" } }
		G.RUN = { active = true }
		table_discard.reset()
		table_discard.record_discard()
		table_discard.record_discard()
		T.assert_equal(table_discard.discards_left(), 0)

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
		G.placement_table = { area = { cards = {}, hard_set_cards = function() end } }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.VoucherDiscard = table_discard
		WORD_GAME.Jumble = { ensure_playable_puzzle = function() end }

		deck.deal_jumble_hand()
		T.assert_equal(table_discard.discards_left(), 2, "new hand should restore voucher discards")

		MockEnv.reset_game()
	end)

	T.it("exposes voucher counter layout starting at 2 on the discard_bin imprint", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		setup_unlocked_voucher_discard()
		table_discard.reset()
		table_discard.sync_voucher_counter(true)

		local layout = table_discard.voucher_counter_layout(discard_bin_imprint(), 170, 90, 80, 40)
		T.assert_not_nil(layout, "counter layout should be available when voucher discard is unlocked")
		T.assert_equal(layout.value, 2)
		T.assert_true(layout.cx > layout.art_x, "counter should sit inside the voucher art")
		T.assert_true(layout.height > 0)
		T.assert_equal(table_discard.visible_counter_digit(), "2")

		MockEnv.reset_game()
	end)

	T.it("keeps voucher counter layout visible at 0 for the rollover animation", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		setup_unlocked_voucher_discard()
		table_discard.reset()
		table_discard.record_discard()
		table_discard.record_discard()
		T.assert_equal(table_discard.discards_left(), 0)

		local layout = table_discard.voucher_counter_layout(discard_bin_imprint(), 170, 90, 80, 40)
		T.assert_not_nil(layout, "counter should stay visible when discards are exhausted")
		T.assert_equal(layout.value, 0)
		T.assert_equal(table_discard.visible_counter_digit(), "1",
			"rollover animation shows the outgoing digit before settling on 0")

		local odometer = table_discard.overlay_odometer()
		odometer.roll = nil
		odometer.display_count = 0
		T.assert_equal(table_discard.visible_counter_digit(), "0")

		MockEnv.reset_game()
	end)

	T.it("draw_voucher_overlay prints the counter digit on the voucher", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		setup_unlocked_voucher_discard()
		table_discard.reset()
		table_discard.sync_voucher_counter(true)

		local printed = {}
		local orig_print = love.graphics.print
		love.graphics.print = function(text)
			printed[#printed + 1] = text
		end

		table_discard.draw_voucher_overlay(discard_bin_imprint(), 170, 90, 80, 40)

		love.graphics.print = orig_print

		local saw_two = false
		for _, text in ipairs(printed) do
			if text == "2" then
				saw_two = true
				break
			end
		end
		T.assert_true(saw_two, "voucher overlay should print the remaining discard count")

		MockEnv.reset_game()
	end)

	T.it("draw_voucher_foreground redraws the voucher above card interaction", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		setup_unlocked_voucher_discard()
		table_discard.reset()
		table_discard.sync_voucher_counter(true)
		mock_discard_voucher({ x = 170, y = 90, w = 80, h = 40 })

		local draws = {}
		local printed = {}
		local orig_draw = love.graphics.draw
		local orig_print = love.graphics.print
		love.graphics.draw = function(...)
			draws[#draws + 1] = true
		end
		love.graphics.print = function(text)
			printed[#printed + 1] = text
		end

		table_discard.draw_voucher_foreground()

		love.graphics.draw = orig_draw
		love.graphics.print = orig_print

		T.assert_true(#draws >= 1, "foreground pass should redraw the voucher art")
		local saw_two = false
		for _, text in ipairs(printed) do
			if text == "2" then saw_two = true break end
		end
		T.assert_true(saw_two, "foreground pass should redraw the counter")

		MockEnv.reset_game()
	end)

	T.it("dragging a card onto the voucher decreases the odometer counter by 1", function()
		MockEnv.setup()
		local table_discard = require("word_game.ui.perks.discard_bin")
		local deck = require("word_game.model.cards.deck")
		setup_unlocked_voucher_discard()
		G.GAME.word_round = { mode = "jumble" }
		G.GAME.word_score_animating = false
		G.GAME.hand_redraw_animating = false
		G.GAME.round_scores = { cards_discarded = { amt = 0 } }
		G.TIMELINE = nil
		G.CARD_W = 1
		G.CARD_H = 1.4
		table_discard.reset()
		table_discard.sync_voucher_counter(true)
		mock_discard_voucher()

		G.discard = {
			T = { x = 17.5, y = 9.2, w = 0.58, h = 0.81 },
			cards = {},
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
		WORD_GAME.VoucherDiscard = table_discard
		WORD_GAME.Deck = deck
		WORD_GAME.HandShuffle = { sync = function() end }

		local card = card_over_voucher()
		G.hand.cards[1] = card

		T.assert_equal(table_discard.discards_left(), 2)
		T.assert_equal(table_discard.visible_counter_digit(), "2")

		local rolls = {}
		local odometer = table_discard.overlay_odometer()
		odometer.start_roll = function(self, from, to)
			rolls[#rolls + 1] = { from = from, to = to }
			self.display_count = from
			self.roll = { from = from, to = to, t = 0, dur = 0.38 }
		end

		local orig_replacement = deck.draw_jumble_replacement
		deck.draw_jumble_replacement = function()
			return { id = "new" }
		end

		T.assert_true(table_discard.try_discard(card), "drop on voucher should discard")
		T.assert_equal(table_discard.discards_left(), 1)
		T.assert_equal(rolls[#rolls].from, 2)
		T.assert_equal(rolls[#rolls].to, 1)
		T.assert_equal(table_discard.visible_counter_digit(), "2", "odometer shows roll-from digit while animating")

		odometer.roll = nil
		odometer.display_count = 1
		T.assert_equal(table_discard.visible_counter_digit(), "1", "counter should show 1 after roll completes")

		deck.draw_jumble_replacement = orig_replacement
		MockEnv.reset_game()
	end)
end)
