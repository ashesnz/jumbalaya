--[[ word_game/ui/table/deck/tokens.lua - Sidebar token counter display and rolls ]]

local GameRT = require("word_game.ui.util.game_runtime")
local facade = require("word_game.ui.facade")
local Roll = require("jumbalaya-engine.util.roll")

local TOKEN_HIGHLIGHT_TIME = 0.8
local state = facade.run_state()

local M = {}

function M.attach(deck)
	deck.token_display = nil
	deck.token_roll = nil
	deck.token_pending = 0
	deck.token_highlight = 0
end

function M.reset(deck)
	deck.token_display = nil
	deck.token_roll = nil
	deck.token_pending = 0
	deck.token_highlight = 0
end

function M.start_token_roll(deck, from, to)
	local roll, display = Roll.begin(from, to)
	deck.token_roll = roll
	if roll then
		if display then deck.token_display = display end
	else
		deck.token_display = to
	end
end

function M.bump_token_display(deck)
	deck.token_pending = (deck.token_pending or 0) + 1
	if not deck.token_roll then
		local actual = state.tokens()
		local cur = deck.token_display
		if cur == nil then cur = math.max(0, actual - 1) end
		M.start_token_roll(deck, cur, cur + 1)
	end
end

function M.spend_tokens_display(deck, amount)
	amount = math.floor(amount or 0)
	if amount <= 0 then return end
	deck.token_display = state.tokens()
	deck.token_roll = nil
	deck.token_highlight = TOKEN_HIGHLIGHT_TIME
end

function M.is_token_highlighted(deck)
	return (deck.token_highlight or 0) > 0
end

function M.token_count(deck)
	if deck.token_roll then
		return Roll.halfway(deck.token_roll)
	end
	if deck.token_display ~= nil then
		return deck.token_display
	end
	return state.tokens()
end

function M.update_tokens(deck, dt)
	local runtime = GameRT.game
	dt = dt or (runtime() and runtime().real_dt) or 0.016
	deck.token_highlight = math.max(0, (deck.token_highlight or 0) - dt)
	local actual = state.tokens()
	if deck.token_display == nil then
		deck.token_display = actual
	end
	if deck.token_roll then
		local roll, done = Roll.tick(deck.token_roll, dt)
		deck.token_roll = roll
		if done then
			deck.token_display = done
			if (deck.token_pending or 0) > 0 then
				deck.token_pending = deck.token_pending - 1
				M.start_token_roll(deck, deck.token_display, deck.token_display + 1)
			elseif deck.token_display ~= actual then
				M.start_token_roll(deck, deck.token_display, actual)
			end
		elseif roll and actual ~= roll.to then
			roll.to = actual
		end
	elseif deck.token_display ~= actual then
		M.start_token_roll(deck, deck.token_display, actual)
	end
end

return M
