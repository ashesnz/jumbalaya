--[[ tests/unit/test_boss_e2e.lua - Solve the 1-3 boss word through resolve() and reach the trade/next-hand handoff ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local BOSS = {
	kind = "rigid",
	boss_word = "GARDENING",
	pattern = "_AR_E_I_G",
	display = "_AR_E_I_G",
}

--- Engine-heavy UI the flow doesn't depend on (feedback panels; optional real dissolve).
local function stub_heavy_ui(opts)
	opts = opts or {}
	local wf = require("word_game.ui.feedback.word_feedback")
	local dissolve = require("word_game.ui.effects.dissolve_fx")
	local saved = {}
	-- "Well done!" runs through the REAL spawn_attention panel path (regression: Panel T nesting).
	local C = require("jumbalaya-engine.shell").game().C
	C.GOLD = C.GOLD or { 1, 0.8, 0, 1 }
	C.WHITE = C.WHITE or { 1, 1, 1, 1 }
	C.CLEAR = C.CLEAR or { 0, 0, 0, 0 }
	for _, name in ipairs({ "show_on_play_board", "show", "show_boss_countdown" }) do
		saved[name] = wf[name]
		wf[name] = function() end
	end
	local orig_run = dissolve.run
	if not opts.real_dissolve then
		dissolve.run = function(_, opts_in)
			if opts_in and opts_in.on_finish then opts_in.on_finish() end
		end
	end
	return function()
		for name, fn in pairs(saved) do wf[name] = fn end
		if not opts.real_dissolve then dissolve.run = orig_run end
	end
end

local function pump_timeline(until_fn, max_steps)
	local game = require("jumbalaya-engine.shell").game()
	for _ = 1, max_steps or 3000 do
		game.TIMERS.REAL = (game.TIMERS.REAL or 0) + 0.05
		game.TIMERS.TOTAL = (game.TIMERS.TOTAL or 0) + 0.05
		local ok, err = xpcall(function() game.TIMELINE:advance(0.05) end, debug.traceback)
		if not ok then error(err, 0) end
		if until_fn and until_fn() then return true end
	end
	return false
end

local function make_card(letter)
	return {
		ability = { letter = letter },
		config = { card = { letter = letter } },
		T = { x = 0, y = 0, w = 1, h = 1.4, r = 0 },
		VT = { x = 0, y = 0, w = 1, h = 1.4, r = 0 },
		states = { visible = true, drag = {}, collide = {}, hover = {}, click = {} },
		set_card_area = function() end,
		remove_from_area = function(self) self.area = nil end,
		set_selected = function() end,
		set_scene_parent = function() end,
		snap_rect = function(self, x, y)
			if x then self.T.x, self.T.y = x, y end
		end,
	}
end

local function setup_boss_round()
	mock_env.reset_game()
	mock_env.install_presentation()
	local play = mock_env.install_hand_clear(require("word_game.model.jumble_play"))
	mock_env.patch_game({
		run_mode = "time_run",
		word_score_animating = false,
		word_round = {
			mode = "jumble",
			set = 1,
			hand_index = 3,
			target = 2,
			played_words = {},
			jumble = {
				total_score = 2,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
			},
		},
	})

	local game_access = require("word_game.model.game_access")
	game_access.dispatch({ type = "JUMBLE_PREPARE_BOSS_WORD", boss = BOSS })
	local Jumble = require("word_game.model.jumble")
	T.assert_true(Jumble.reveal_boss_puzzle(), "boss puzzle should reveal")
	return play, game_access, Jumble
end

local function fill_blanks(Jumble)
	local j = Jumble.state()
	local blanks = { "G", "D", "N", "N" }
	local n = 0
	for _, slot in ipairs(j.slots) do
		if slot.kind == "blank" then
			n = n + 1
			slot.card = make_card(blanks[n])
		end
	end
	T.assert_equal(n, 4, "pattern _AR_E_I_G has four blanks")
end

local function run_real_cards_scenario(run_mode, real_token, via_intro, opts)
	opts = opts or {}
	mock_env.ensure_card_class()
	mock_env.reset_game()
	mock_env.install_presentation()
	local shell = require("jumbalaya-engine.shell")
	local game = shell.game()
	game.draw_pile = CardPile(0, 0, game.CARD_W, game.CARD_H, { type = "deck", card_limit = 52 })
	game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
		type = "hand", card_limit = 9, selection_limit = 9,
	})
	game.dealt_letters.states = game.dealt_letters.states or {}
	game.dealt_letters.states.visible = true
	game.pattern_row = game.pattern_row or {}
	game.pattern_row.area = CardPile(0, 0, game.CARD_W * 9, game.CARD_H, {
		type = "hand", card_limit = 9, selection_limit = 9,
	})
	game.pattern_row.relayout = function() end
	game.pattern_row.apply_screen_position = function() end
	game.pattern_row.on_remove_card = function() end
	local play = mock_env.install_hand_clear(require("word_game.model.jumble_play"))

	mock_env.patch_game({
		run_mode = run_mode,
		word_score_animating = false,
		word_round = {
			mode = "jumble", set = 1, hand_index = 3, target = 2, played_words = {},
			jumble = { total_score = 2, puzzle_points = 0, puzzle_multi = 1.0, puzzle_words = {} },
		},
	})
	local game_access = require("word_game.model.game_access")
	local Jumble = require("word_game.model.jumble")
	local deck = require("word_game.model.cards.deck")
	deck.commit_pile_hosts = deck.commit_pile_hosts or function() end
	local letters
	if via_intro then
		-- Real pre-boss clear -> boss intro (countdown, deal, reveal).
		_G.WORD_GAME_UI.PlayEffects = require("word_game.ui.play_effects")
		if not _G.get_hand_area_width then
			function get_hand_area_width(hand_size)
				return (hand_size or 7) * 0.78
			end
		end
		local restore_intro = stub_heavy_ui()
		local ok_clear, err_clear = pcall(play.on_hand_cleared)
		local ok_pump, revealed = pcall(pump_timeline, function()
			local live = Jumble.state()
			return live and live.boss_word_active
		end)
		restore_intro()
		T.assert_true(ok_clear, "pre-boss on_hand_cleared raised: " .. tostring(err_clear))
		T.assert_true(ok_pump, "boss intro raised: " .. tostring(revealed))
		local live = Jumble.state()
		T.assert_true(revealed, string.format(
			"boss intro must reveal (staging=%s hidden=%s pending=%s)",
			tostring(live and live.boss_word_staging), tostring(live and live.boss_puzzle_hidden),
			tostring(live and live.pending_boss ~= nil)))
		BOSS = Jumble.state().puzzle
		letters = Jumble.boss_hand_letters(BOSS.boss_word, BOSS.pattern)
	else
		game_access.dispatch({ type = "JUMBLE_PREPARE_BOSS_WORD", boss = BOSS })
		T.assert_true(Jumble.reveal_boss_puzzle())
		letters = Jumble.boss_hand_letters(BOSS.boss_word, BOSS.pattern)
		deck.deal_boss_hand(letters, function() end, { instant_deal = true })
	end
	T.assert_equal(#game.dealt_letters.cards, #letters, "boss hand dealt")

	-- Place each hidden letter into its blank, like a drag-drop.
	local j = Jumble.state()
	local blank_letters = {}
	for i = 1, #BOSS.pattern do
		if BOSS.pattern:sub(i, i) == "_" then
			blank_letters[#blank_letters + 1] = BOSS.boss_word:sub(i, i)
		end
	end
	local used = {}
	local n = 0
	for slot_index, slot in ipairs(j.slots) do
		if slot.kind == "blank" then
			n = n + 1
			local want = blank_letters[n]
			local found
			for _, card in ipairs(game.dealt_letters.cards) do
				if not used[card] and card.ability and card.ability.letter == want then
					found = card
					break
				end
			end
			T.assert_not_nil(found, "hand has a card for " .. want)
			used[found] = true
			game.dealt_letters:remove_card(found)
			T.assert_true(Jumble.assign_card_to_blank(slot_index, found))
		end
	end
	T.assert_equal(#game.pattern_row.area.cards, #letters, "cards placed on the row")

	local restore = stub_heavy_ui(opts)
	local trade_opened, dealt = false, false
	_G.WORD_GAME_UI.TradeUI = { open_then_dealer = function() trade_opened = true end }
	if real_token then
		_G.WORD_GAME_UI.TokenReward = require("word_game.ui.table.token_reward")
		_G.WORD_GAME_UI.HandClearFocus = require("word_game.ui.tutorial.hand_clear_focus")
	end
	local cards_fx = require("word_game.ui.play_effects.animate.cards")
	local orig_deal = cards_fx.deal_and_refresh
	cards_fx.deal_and_refresh = function(cb) dealt = true; if cb then cb() end end

	local resolution = require("word_game.ui.play_effects.resolution")
	local ok, result = pcall(resolution.resolve, play, { instant = true })
	T.assert_true(ok, "resolve raised: " .. tostring(result))
	T.assert_equal(result.kind, "word_play", "play result: " .. tostring(result.err))
	T.assert_true(result.boss_word_cleared)
	T.assert_equal(#result.used_cards, #letters, "used cards")

	local reached = pump_timeline(function()
		if real_token and _G.WORD_GAME_UI.TokenReward.update then
			_G.WORD_GAME_UI.TokenReward.update(0.05)
		end
		return trade_opened
	end)
	cards_fx.deal_and_refresh = orig_deal
	restore()

	local stack = require("word_game.model.jumble.bonus_stack")
	T.assert_false(dealt, "must not take normal deal/refresh path")
	T.assert_true(reached, string.format(
		"trade must open (stack_animating=%s stack_cards=%d score_animating=%s)",
		tostring(stack.is_animating()), #(stack.cards() or {}),
		tostring(game_access.get().word_score_animating)))
	T.assert_equal(#(stack.cards() or {}), #letters, "cards parked in the gutter")
	local j_live = game_access.word_round().jumble
	if j_live and j_live.boss_cards then
		T.assert_equal(#(stack.cards() or {}), #j_live.boss_cards, "gutter matches boss hand")
	end

	-- Close the marketplace -> dealer -> next hand.
	local game_after = shell.game()
	game_after.SETTINGS = game_after.SETTINGS or {}
	local ok_next, err_next = pcall(function()
		play.continue_after_dealer()
		pump_timeline(function()
			local wr = game_access.word_round()
			return wr and wr.hand_index ~= 3
		end, 400)
	end)
	T.assert_true(ok_next, "continue_after_dealer raised: " .. tostring(err_next))
	local wr_next = game_access.word_round()
	T.assert_equal(wr_next.set, 1)
	T.assert_equal(wr_next.hand_index, 4, "advances to the next hand after the boss")
	T.assert_false(wr_next.jumble.boss_word_active == true, "boss state cleared on next hand")
	for _, card in ipairs(stack.cards()) do
		T.assert_true(card.bonus_card, "gutter card is gold bonus")
		T.assert_false(card.REMOVED and true or false, "gutter card not destroyed")
	end
end

T.describe("boss word end to end (1-3)", function()
	T.it("reveal marks the round as boss_word_active", function()
		local _, game_access = setup_boss_round()
		local j = game_access.word_round().jumble
		T.assert_true(j.boss_word_active, "boss_word_active after reveal")
		T.assert_equal(j.puzzle.boss_word, "GARDENING")
	end)

	T.it("playing the boss word hands off to boss clear, not a hand refresh", function()
		local play, game_access, Jumble = setup_boss_round()
		fill_blanks(Jumble)

		local gutter_called, cleared_opts, dealt = false, nil, false
		local boss_success = require("word_game.ui.play_effects.animate.boss_success")
		local orig_success = boss_success.present_boss_word_success
		boss_success.present_boss_word_success = function(_, _, _, on_hand_cleared)
			gutter_called = true
			if on_hand_cleared then on_hand_cleared({ boss_cleared = true }) end
		end
		local cards = require("word_game.ui.play_effects.animate.cards")
		local orig_deal = cards.deal_and_refresh
		cards.deal_and_refresh = function(cb)
			dealt = true
			if cb then cb() end
		end
		local orig_clear = play.on_hand_cleared
		play.on_hand_cleared = function(opts)
			cleared_opts = opts or {}
		end

		local resolution = require("word_game.ui.play_effects.resolution")
		local result = resolution.resolve(play, { instant = true })

		boss_success.present_boss_word_success = orig_success
		cards.deal_and_refresh = orig_deal
		play.on_hand_cleared = orig_clear

		T.assert_not_nil(result)
		T.assert_equal(result.kind, "word_play", "result: " .. tostring(result.kind) .. " " .. tostring(result.err))
		T.assert_equal(result.word, "GARDENING")
		T.assert_true(result.boss_word_cleared)
		T.assert_true(gutter_called, "gutter choreography must run")
		T.assert_false(dealt, "must not take the normal deal/refresh path")
		T.assert_true(cleared_opts and cleared_opts.boss_cleared, "on_hand_cleared({boss_cleared=true})")
	end)

	T.it("real chain: solve -> gutter -> boss clear -> trade opens, boss state cleared", function()
		local play, game_access, Jumble = setup_boss_round()
		fill_blanks(Jumble)

		-- Feedback panels need real engine layout; the flow under test doesn't.
		local wf = require("word_game.ui.feedback.word_feedback")
		local saved_wf = {}
		-- "Well done!" runs through the REAL spawn_attention panel path (regression: Panel T nesting).
		local C = require("jumbalaya-engine.shell").game().C
		C.GOLD = C.GOLD or { 1, 0.8, 0, 1 }
		C.WHITE = C.WHITE or { 1, 1, 1, 1 }
		C.CLEAR = C.CLEAR or { 0, 0, 0, 0 }
		for _, name in ipairs({ "show_on_play_board", "show", "show_boss_countdown" }) do
			saved_wf[name] = wf[name]
			wf[name] = function() end
		end

		local dissolve = require("word_game.ui.effects.dissolve_fx")
		local orig_dissolve_run = dissolve.run
		dissolve.run = function(_, opts)
			if opts and opts.on_finish then opts.on_finish() end
		end

		local trade_opened = false
		_G.WORD_GAME_UI.TradeUI = {
			open_then_dealer = function() trade_opened = true end,
		}
		local dealt = false
		local cards = require("word_game.ui.play_effects.animate.cards")
		local orig_deal = cards.deal_and_refresh
		cards.deal_and_refresh = function(cb)
			dealt = true
			if cb then cb() end
		end

		local resolution = require("word_game.ui.play_effects.resolution")
		local ok, err = pcall(resolution.resolve, play, { instant = true })
		cards.deal_and_refresh = orig_deal
		T.assert_true(ok, "resolve raised: " .. tostring(err))

		-- Drain any queued timeline events.
		local game = require("jumbalaya-engine.shell").game()
		local drain_err
		for _ = 1, 3000 do
			game.TIMERS.REAL = (game.TIMERS.REAL or 0) + 0.05
			game.TIMERS.TOTAL = (game.TIMERS.TOTAL or 0) + 0.05
			local ok_t, terr = xpcall(function() game.TIMELINE:advance(0.05) end, debug.traceback)
			if not ok_t then
				drain_err = terr
				break
			end
			if trade_opened then break end
		end
		for name, fn in pairs(saved_wf) do wf[name] = fn end
		dissolve.run = orig_dissolve_run
		T.assert_true(drain_err == nil, "timeline raised: " .. tostring(drain_err))
		local stack = require("word_game.model.jumble.bonus_stack")
		local diag = string.format(
			"stack_animating=%s stack_cards=%d score_animating=%s",
			tostring(stack.is_animating()),
			#(stack.cards() or {}),
			tostring(game_access.get().word_score_animating)
		)

		T.assert_false(dealt, "must not take the normal deal/refresh path")
		T.assert_true(trade_opened, "trade must open after boss clear: " .. diag)
		local j = game_access.word_round().jumble
		T.assert_false(j.boss_word_active, "boss state cleared")
	end)

	T.it("full intro: pre-boss clear -> countdown -> reveal -> solve opens trade", function()
		run_real_cards_scenario("time_run", true, true)
	end)
	T.it("full intro (classic): pre-boss clear -> reveal -> solve opens trade", function()
		run_real_cards_scenario("classic", true, true)
	end)

	for _, mode in ipairs({ "time_run", "classic" }) do
		T.it("real cards, " .. mode .. ": solve opens trade", function()
			run_real_cards_scenario(mode, false)
		end)
		T.it("real cards, " .. mode .. " + real TokenReward: solve opens trade", function()
			run_real_cards_scenario(mode, true)
		end)
	end

	T.it("real dissolve: boss cards become gold in the left gutter", function()
		run_real_cards_scenario("time_run", false, false, { real_dissolve = true })
	end)

	T.it("boss gutter uses store boss_cards when pattern_row is empty", function()
		mock_env.ensure_card_class()
		mock_env.reset_game()
		mock_env.install_presentation()
		local shell = require("jumbalaya-engine.shell")
		local game = shell.game()
		game.draw_pile = CardPile(0, 0, game.CARD_W, game.CARD_H, { type = "deck", card_limit = 52 })
		game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
			type = "hand", card_limit = 9, selection_limit = 9,
		})
		game.pattern_row = { area = CardPile(0, 0, game.CARD_W * 9, game.CARD_H, {
			type = "hand", card_limit = 9, selection_limit = 9,
		}), relayout = function() end, apply_screen_position = function() end, on_remove_card = function() end }
		local play = mock_env.install_hand_clear(require("word_game.model.jumble_play"))
		mock_env.patch_game({
			run_mode = "time_run",
			word_round = {
				mode = "jumble", set = 1, hand_index = 3, target = 2, played_words = {},
				jumble = { total_score = 2, puzzle_points = 0, puzzle_multi = 1.0, puzzle_words = {} },
			},
		})
		local game_access = require("word_game.model.game_access")
		local Jumble = require("word_game.model.jumble")
		local deck = require("word_game.model.cards.deck")
		deck.commit_pile_hosts = deck.commit_pile_hosts or function() end
		game_access.dispatch({ type = "JUMBLE_PREPARE_BOSS_WORD", boss = BOSS })
		T.assert_true(Jumble.reveal_boss_puzzle())
		local j = Jumble.state()
		local puzzle = j.puzzle
		T.assert_not_nil(puzzle and puzzle.boss_word)
		local letters = Jumble.boss_hand_letters(puzzle.boss_word, puzzle.pattern)
		deck.deal_boss_hand(letters, function() end, { instant_deal = true })
		j = Jumble.state()
		local used = {}
		local n = 0
		for slot_index, slot in ipairs(j.slots) do
			if slot.kind == "blank" then
				n = n + 1
				local want = puzzle.boss_word:sub(slot.index, slot.index)
				local found
				for _, card in ipairs(game.dealt_letters.cards) do
					if not used[card] and card.ability and card.ability.letter == want then
						found = card
						break
					end
				end
				T.assert_not_nil(found, "hand has " .. want)
				used[found] = true
				game.dealt_letters:remove_card(found)
				T.assert_true(Jumble.assign_card_to_blank(slot_index, found))
			end
		end
		-- Simulate pattern_row desync (slots still hold the play).
		game.pattern_row.area.cards = {}
		game.pattern_row.area:hard_set_cards()

		local restore = stub_heavy_ui()
		_G.WORD_GAME_UI.TradeUI = { open_then_dealer = function() end }
		local cards_fx = require("word_game.ui.play_effects.animate.cards")
		local orig_deal = cards_fx.deal_and_refresh
		cards_fx.deal_and_refresh = function() end
		local resolution = require("word_game.ui.play_effects.resolution")
		local ok, err = pcall(resolution.resolve, play, { instant = true })
		cards_fx.deal_and_refresh = orig_deal
		T.assert_true(ok, tostring(err))
		local trade_opened = false
		_G.WORD_GAME_UI.TradeUI = { open_then_dealer = function() trade_opened = true end }
		pump_timeline(function() return trade_opened end, 5000)
		restore()
		local stack = require("word_game.model.jumble.bonus_stack")
		T.assert_equal(#(stack.cards() or {}), #letters, "boss_cards still reach the gutter")
		T.assert_true(trade_opened, "trade opens after gutter")
	end)

	T.it("boss_cleared resolves to the trade handoff", function()
		local play = setup_boss_round()
		T.assert_equal(play.resolve_after_clear({ boss_cleared = true }), "boss_bonus_hand")
	end)
end)
