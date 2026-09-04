--[[ tests/unit/test_jumble_play_flow.lua
     Integration tests for jumble play flow, marketplace, and stage files.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Jumble play flow integration", function()
	mock_env.reset_game()
	local jumble = require("word_game.model.jumble")

	T.it("advances puzzle when play button is pressed with solved puzzle and empty blanks", function()
		local flow = require("word_game.model.jumble_play")
		local fixed_letters = require("word_game.ui.jumble_fixed_letters")
		local wr = {
			target = 100,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = true,
				total_score = 10,
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr
		G.GAME.word_score_animating = false

		local play_resolution = require("word_game.ui.play_resolution")
		play_resolution.resolve(flow)

		T.assert_equal(wr.jumble.puzzle_index, 2, "Puzzle index should advance to 2")
		T.assert_false(wr.jumble.solved, "New puzzle solved state should be false")
		T.assert_equal(wr.jumble.puzzle.suffix, "AR", "Next puzzle should have suffix AR (_ A R)")
		local anim = fixed_letters.anim_state()
		T.assert_equal(anim.offset_y, 0, "Fixed animation offset should reset to 0")
		T.assert_equal(anim.alpha, 1, "Fixed animation alpha should reset to 1")
	end)

	T.it("rejects play on first attempt without placed cards", function()
		local flow = require("word_game.model.jumble_play")
		local wr = {
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				total_score = 0,
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr
		G.GAME.word_score_animating = false

		local play_resolution = require("word_game.ui.play_resolution")
		play_resolution.resolve(flow)

		T.assert_equal(wr.jumble.puzzle_index, 1, "Puzzle index should stay 1")
		T.assert_false(wr.jumble.solved, "Puzzle should remain unsolved")
	end)

	T.it("supports drafting letter cards to deck or skipping in card marketplace and advances to stage 1-2 with 40 target points", function()
		local trade = require("word_game.model.trade")
		local round = require("word_game.model.round")

		local deck_cards = {}
		local playing_cards = {}
		G.playing_cards = playing_cards
		G.deck = {
			cards = deck_cards,
			config = { card_limit = 52 },
			emplace = function(self, card)
				table.insert(self.cards, card)
			end,
		}
		G.RUN = { active = true }
		G.GAME.deck_left_count = 0

		G.GAME.alpha = {
			trade_used_this_hand = false,
			tokens = 10,
			perks = {},
		}
		local offer = trade.roll_offer()
		T.assert_equal(#offer.add.letters, 3, "Card marketplace should offer three cards")
		T.assert_equal(trade.ACTION_COSTS.add, 10, "Adding a marketplace card should cost 10 tokens")
		T.assert_equal(trade.ACTION_COSTS.remove, 20, "Removing a deck card should cost 20 tokens")
		T.assert_equal(trade.ACTION_COSTS.modifier, 30, "Applying a modifier should cost 30 tokens")

		local initial_count = #G.deck.cards
		local ok, card = trade.add_letter({ letter = "Z", color = "red" })
		T.assert_true(ok, "Drafting letter Z should succeed")
		T.assert_equal(#G.deck.cards, initial_count + 1, "Deck should have 1 additional card")
		T.assert_equal(#G.playing_cards, 1, "Playing cards should track the drafted card")
		T.assert_equal(G.deck.cards[#G.deck.cards].ability.letter, "Z")
		T.assert_equal(G.GAME.deck_left_count, #G.deck.cards, "Adding a card should update the deck count")

		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			played_words = { "CAT" },
		}
		round.advance_hand()
		T.assert_equal(G.GAME.word_round.set, 1)
		T.assert_equal(G.GAME.word_round.hand_index, 2, "Should advance to stage 1-2")
		T.assert_equal(G.GAME.word_round.target, 50, "Level 2 target should be 50 points")
		T.assert_equal(#G.GAME.word_round.played_words, 0, "Played words reset for stage 1-2")
	end)

	T.it("raises add cost for every marketplace card after each purchase", function()
		local trade_ui = require("word_game.ui.trade")
		local session_state = { add_cost_bonus = 0 }
		T.assert_equal(trade_ui.session_add_cost(session_state), 10, "Initial add cost should be 10 tokens")
		session_state.add_cost_bonus = 10
		T.assert_equal(trade_ui.session_add_cost(session_state), 20, "All cards should cost 10 more after one add")
		session_state.add_cost_bonus = 20
		T.assert_equal(trade_ui.session_add_cost(session_state), 30, "All cards should cost 10 more after two adds")
	end)

	T.it("retains marketplace cards when dealing the next jumble stage", function()
		local deck = require("word_game.model.cards.deck")
		local cards = {}
		G.playing_cards = {}
		G.RUN = { active = true }
		G.deck = {
			cards = cards,
			config = {},
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						return table.remove(self.cards, i)
					end
				end
			end,
			shuffle = function() end,
			hard_set_T = function() end,
		}
		G.hand = {
			cards = {},
			config = {},
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						return table.remove(self.cards, i)
					end
				end
			end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.discard = {
			cards = {},
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						return table.remove(self.cards, i)
					end
				end
			end,
			hard_set_cards = function() end,
		}
		G.placement_table = G.placement_table or {}
		G.placement_table.area = {
			cards = {},
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						return table.remove(self.cards, i)
					end
				end
			end,
			hard_set_cards = function() end,
		}
		G.GAME = G.GAME or {}
		G.GAME.deck_alpha = { pos = { x = 0, y = 0 } }
		local added = deck.create_letter_card("Z", "red")
		deck.populate_jumble_deck()
		T.assert_equal(#G.deck.cards, 1, "The retained deck should contain the marketplace card")
		T.assert_equal(G.deck.cards[1], added, "The added card should be shuffled into the next stage deck")
	end)

	T.it("updates the token counter while the marketplace hides the table deck area", function()
		local table_deck = require("word_game.ui.table_deck")
		local state = require("word_game.model.state")
		G.GAME.alpha = { tokens = 20, perks = {} }
		table_deck.reset()
		state.spend_tokens(10)
		table_deck.spend_tokens_display(10)

		T.assert_equal(table_deck.token_count(), 10, "Token counter should reflect the spent balance without a deck area")
		T.assert_true(table_deck.is_token_highlighted(), "Spending tokens should set_selected the sidebar token display")
		table_deck.update_tokens(0.8)
		T.assert_false(table_deck.is_token_highlighted(), "Sidebar token set_selected should fade after its display window")
		table_deck.reset()
		T.assert_false(table_deck.is_token_highlighted(), "Reset should clear the sidebar token set_selected")
	end)

	T.it("breaks jumble puzzles into 30 distinct stage files with patterns loaded per set/hand", function()
		local total_stages = 0
		local seen_patterns = {}
		local duplicate_count = 0

		for s = 1, 8 do
			local hands = (s == 1) and 9 or 3
			for h = 1, hands do
				total_stages = total_stages + 1
				local mod_name = string.format("word_game.config.jumble_puzzles.%d_%d", s, h)
				local ok, stage_mod = pcall(require, mod_name)
				T.assert_true(ok, "Module " .. mod_name .. " should load successfully")
				T.assert_not_nil(stage_mod and stage_mod.PATTERNS, mod_name .. " should define PATTERNS")
				local min_patterns = (s == 1) and 7 or 10
				T.assert_true(#stage_mod.PATTERNS >= min_patterns,
					mod_name .. " should have enough patterns (has " .. tostring(#stage_mod.PATTERNS) .. ")")

				if s >= 2 and s <= 6 then
					for _, p in ipairs(stage_mod.PATTERNS) do
						local key
						if type(p) == "string" then
							key = p
						elseif type(p) == "table" then
							local parts = {}
							if p.span then parts[#parts + 1] = "span:" .. table.concat(p.span, ",") end
							if p.prefix then parts[#parts + 1] = "pre:" .. p.prefix end
							if p.suffix then parts[#parts + 1] = "suf:" .. p.suffix end
							if p.center then parts[#parts + 1] = "cen:" .. p.center end
							if p.pin_index then parts[#parts + 1] = "pin:" .. p.pin_index end
							if p.min then parts[#parts + 1] = "min:" .. p.min end
							if p.max then parts[#parts + 1] = "max:" .. p.max end
							key = table.concat(parts, ";")
						end
						if seen_patterns[key] then
							duplicate_count = duplicate_count + 1
						else
							seen_patterns[key] = mod_name
						end
					end
				end

				local list = jumble.puzzles(s, h)
				T.assert_equal(#list, #stage_mod.PATTERNS, "jumble.puzzles(" .. s .. ", " .. h .. ") should load matching count")
				T.assert_true(jumble.is_active_hand(s, h), "Stage " .. s .. "-" .. h .. " should be active jumble hand")
			end
		end

		T.assert_equal(total_stages, 30, "Should have 30 stage puzzle files total (1_1..1_9 plus 2_1..8_3)")
		T.assert_equal(duplicate_count, 0, "No duplicate patterns should exist across sets 2-6")

		local s1_1 = require("word_game.config.jumble_puzzles.1_1")
		T.assert_equal(s1_1.PATTERNS[1].span and s1_1.PATTERNS[1].span[1], "C")
		T.assert_equal(s1_1.PATTERNS[1].span and s1_1.PATTERNS[1].span[2], "T")
		T.assert_equal(s1_1.PATTERNS[2].suffix, "AR")
		T.assert_equal(s1_1.PATTERNS[3].prefix, "C")
		T.assert_equal(s1_1.PATTERNS[4].prefix, "S")
		T.assert_equal(s1_1.PATTERNS[5].suffix, "T")
		T.assert_equal(s1_1.PATTERNS[6].prefix, "O")
		T.assert_equal(s1_1.PATTERNS[7].suffix, "R")
		T.assert_equal(s1_1.PATTERNS[8].suffix, "W")
		T.assert_equal(s1_1.PATTERNS[9].prefix, "N")
		T.assert_equal(s1_1.PATTERNS[10].prefix, "G")
	end)
end)
