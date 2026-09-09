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
		local fixed_letters = require("word_game.ui.table.jumble_fixed_letters")
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

		local play_resolution = require("word_game.ui.play_effects.resolution")
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

		local play_resolution = require("word_game.ui.play_effects.resolution")
		play_resolution.resolve(flow)

		T.assert_equal(wr.jumble.puzzle_index, 1, "Puzzle index should stay 1")
		T.assert_false(wr.jumble.solved, "Puzzle should remain unsolved")
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

	T.it("updates the token counter while the marketplace hides the table deck area", function()
		local table_deck = require("word_game.ui.table.deck")
		local state = require("word_game.model.state")
		G.GAME.run_state = { tokens = 20, perks = {} }
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
