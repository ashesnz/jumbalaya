--[[ tests/helpers/classic_stage_advance.lua
     Shared fixture for classic Next → marketplace → stage advance tests.
]]

local mock_env = require("tests.helpers.mock_env")
local InputLock = require("word_game.model.input_lock")

local deck = require("word_game.model.cards.deck")
local play = require("word_game.model.play")
local trade = require("word_game.model.trade")
local hand_size = require("word_game.config.hand_size")
local jumble = require("word_game.model.jumble")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

local function default_jumble(opts)
	return {
		total_score = opts.total_score or 32,
		puzzle_points = 0,
		puzzle_multi = 1.0,
		puzzle_words = {},
		solved = false,
		slots = {},
	}
end

function M.setup_card_areas()
	mock_env.ensure_engine_globals()
	require("word_game.ui.cardarea")
	require("word_game.model.cards.card")

	G.deck = CardArea(0, 0, 1, 1, { type = "deck", card_limit = 52 })
	G.hand = CardArea(0, 0, 7, 1, { type = "hand", card_limit = 7 })
	G.discard = CardArea(0, 0, 1, 1, { type = "discard", card_limit = 500 })
	G.placement_table = {
		area = CardArea(0, 0, 5, 1, { type = "play" }),
		on_remove_card = function() end,
		relayout = function() end,
		apply_screen_position = function() end,
	}
	G.GAME.deck_alpha = { pos = { x = 0, y = 0 } }
	G.RUN = { active = true }
end

function M.wire_player_host_drag()
	WORD_GAME = WORD_GAME or {}
	WORD_GAME.PlayerHost = {
		allows_card_drag = function(area)
			if InputLock.is_table_busy() then
				return false
			end
			if WORD_GAME and WORD_GAME.HandClearFocus and WORD_GAME.HandClearFocus.is_active
				and WORD_GAME.HandClearFocus.is_active() then
				return false
			end
			return true
		end,
		refresh_card_input = function()
			if G.hand and G.hand.set_ranks then
				G.hand:set_ranks()
			end
		end,
	}
	WORD_GAME.PlayHoldRedraw = WORD_GAME.PlayHoldRedraw or {
		is_animating = function() return false end,
	}
end

function M.wire_word_game_stubs()
	WORD_GAME.Deck = deck
	WORD_GAME.Jumble = jumble
	jumble.ensure_playable_puzzle = function() return true end
	jumble.refresh_hud = function() end
	WORD_GAME.Play = play
	WORD_GAME.TableDiscard = { reset = function() end }
	WORD_GAME.HandClearFocus = {
		end_focus = function() end,
		is_active = function() return false end,
	}
	WORD_GAME.TradeUI = { open_then_dealer = function() end }
	WORD_GAME.TokenReward = {
		try_award = function(callback)
			if callback then callback() end
			return true
		end,
		is_active = function() return false end,
	}
	WORD_GAME.Confetti = { burst = function() end }
end

function M.configure_round(opts)
	opts = opts or {}
	G.GAME.run_mode = "classic"
	G.GAME.alpha = { tokens = 100, perks = {}, trade_used_this_hand = false }
	G.GAME.word_round = {
		set = opts.set or 1,
		hand_index = opts.hand_index or 1,
		target = opts.target or 25,
		mode = "jumble",
		played_words = {},
		jumble = opts.jumble or default_jumble(opts),
	}
end

function M.make_timeline()
	local events = {}
	G.TIMELINE = {
		enqueue = function(_, ev)
			events[#events + 1] = ev
		end,
	}
	return function()
		while #events > 0 do
			local ev = table.remove(events, 1)
			if ev.func then ev.func() end
		end
	end
end

function M.stub_word_feedback()
	local orig_show = word_feedback.show
	word_feedback.show = function() end
	return function()
		word_feedback.show = orig_show
	end
end

function M.assert_hand_draggable(T, label)
	for i, card in ipairs(G.hand.cards or {}) do
		T.assert_true(card.states and card.states.drag and card.states.drag.can,
			(label or "Hand") .. " card " .. i .. " must be draggable")
	end
end

function M.add_letters(letters)
	for _, spec in ipairs(letters) do
		trade.add_letter(spec)
	end
end

function M.begin(opts)
	opts = opts or {}
	mock_env.reset_game()
	M.setup_card_areas()
	if opts.wire_drag then
		M.wire_player_host_drag()
	end
	if opts.table_board then
		G.STATES = G.STATES or {}
		G.STATE = G.STATES.TABLE_BOARD
	end

	M.wire_word_game_stubs()
	M.configure_round(opts)

	deck.populate_starting_deck()
	if opts.deal ~= false then
		deck.deal_jumble_hand()
	end

	local restore_feedback = M.stub_word_feedback()
	local drain = M.make_timeline()

	return {
		deck = deck,
		play = play,
		trade = trade,
		hand_size = hand_size,
		starter = #deck.STARTING_LETTERS,
		drain = drain,
		restore = restore_feedback,
		clear_hand = function()
			play.on_hand_cleared()
			drain()
		end,
		continue = function()
			play.continue_after_dealer()
			drain()
		end,
		advance = function(purchase_letters)
			play.on_hand_cleared()
			drain()
			if purchase_letters then
				M.add_letters(purchase_letters)
			end
			play.continue_after_dealer()
			drain()
		end,
	}
end

return M
