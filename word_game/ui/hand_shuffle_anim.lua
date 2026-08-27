--[[ word_game/ui/hand_shuffle_anim.lua - Bunny-hop shuffle animation for the hand ]]

local Scheduler = require "app.effects.scheduler"

local M = {}

local animating = false

local SWAP_DURATION = 0.13
local SWAP_GAP = 0.018
local HOP_FRAC = 0.17

function M.is_animating()
	return animating
end

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

local function hop_height()
	return (G.CARD_H or 1.4) * HOP_FRAC
end

local function set_animating(active)
	animating = active
	if G.GAME then
		G.GAME.hand_shuffle_animating = active
	end
end

local function sort_hand_cards(cards)
	if cards[1] and cards[1].sort_id then
		table.sort(cards, function(a, b)
			return (a.sort_id or 1) < (b.sort_id or 2)
		end)
	end
end

--- Mirrors `shuffle_seeded` but records each Fisher-Yates swap for playback.
local function plan_swaps(count, seed)
	if seed then
		math.randomseed(seed)
	end
	local swaps = {}
	for i = count, 2, -1 do
		local j = math.random(i)
		swaps[#swaps + 1] = { i = i, j = j }
	end
	return swaps
end

local function capture_layout(hand)
	hand:relayout()
	local layout = {}
	for _, card in ipairs(hand.cards) do
		layout[card] = {
			x = card.T.x,
			y = card.T.y,
			r = card.T.r or 0,
		}
	end
	return layout
end

local function animate_moves(moves, duration, on_done)
	if #moves == 0 then
		if on_done then on_done() end
		return
	end

	local hop = hop_height()
	local pending = #moves
	local started = G.TIMERS.REAL

	local function finish_card(card)
		card.shuffle_hop = nil
		pending = pending - 1
		if pending <= 0 and on_done then
			on_done()
		end
	end

	for _, move in ipairs(moves) do
		local card = move.card
		card.shuffle_hop = true
		Scheduler.add{
			mode = "window",
			timer = "REAL",
			delay = duration,
			blockable = false,
			blocking = false,
			func = function()
				local u = math.min(1, (G.TIMERS.REAL - started) / duration)
				local e = smoothstep(u)
				card.T.x = move.sx + (move.tx - move.sx) * e
				card.T.y = move.sy + (move.ty - move.sy) * e - hop * math.sin(math.pi * u)
				card.T.r = move.sr + (move.tr - move.sr) * e
				if u >= 1 then
					card.T.x = move.tx
					card.T.y = move.ty
					card.T.r = move.tr
					finish_card(card)
					return true
				end
			end,
		}
	end
end

local function animate_swap(hand, i, j, on_done)
	local before = capture_layout(hand)
	hand.cards[i], hand.cards[j] = hand.cards[j], hand.cards[i]
	hand:relayout()

	local moves = {}
	for _, card in ipairs(hand.cards) do
		local start = before[card]
		if start then
			local tx = card.T.x
			local ty = card.T.y
			local tr = card.T.r or 0
			if math.abs(start.x - tx) > 0.005 or math.abs(start.y - ty) > 0.005 then
				card.T.x = start.x
				card.T.y = start.y
				card.T.r = start.r
				if card.hard_set_T then
					card:hard_set_T()
				end
				moves[#moves + 1] = {
					card = card,
					sx = start.x,
					sy = start.y,
					sr = start.r,
					tx = tx,
					ty = ty,
					tr = tr,
				}
			end
		end
	end

	animate_moves(moves, SWAP_DURATION, on_done)
end

function M.animate(hand, on_complete)
	if animating or not hand or #hand.cards < 2 then
		if on_complete then on_complete() end
		return
	end

	sort_hand_cards(hand.cards)
	local swaps = plan_swaps(#hand.cards, advance_seed("hand_shuffle"))
	if #swaps == 0 then
		if on_complete then on_complete() end
		return
	end

	set_animating(true)
	if play_sfx then
		play_sfx("hover_card", 0.88, 0.45)
	end

	local step = 0
	local function play_next_swap()
		step = step + 1
		local swap = swaps[step]
		if not swap then
			set_animating(false)
			if hand.set_ranks then
				hand:set_ranks()
			end
			hand:relayout()
			hand:snap_VT()
			hand:hard_set_cards()
			if on_complete then
				on_complete()
			end
			return
		end

		animate_swap(hand, swap.i, swap.j, function()
			if play_sfx and step < #swaps then
				play_sfx("card_slide1", 0.9 + (step % 3) * 0.02, 0.22)
			end
			Scheduler.add{
				mode = "delayed",
				timer = "REAL",
				delay = SWAP_GAP,
				blockable = false,
				func = function()
					play_next_swap()
					return true
				end,
			}
		end)
	end

	play_next_swap()
end

return M
