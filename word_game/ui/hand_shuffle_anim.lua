--[[ word_game/ui/hand_shuffle_anim.lua - Smooth riffle shuffle animation for the hand ]]

local Scheduler = require "app.effects.scheduler"

local M = {}

local animating = false

local SHUFFLE_DURATION = 0.44
local STAGGER = 0.034
local LIFT_FRAC = 0.07

function M.is_animating()
	return animating
end

local function smoothstep(u)
	return u * u * (3 - 2 * u)
end

local function lift_height()
	return (G.CARD_H or 1.4) * LIFT_FRAC
end

local function set_animating(active)
	animating = active
	if G.GAME then
		G.GAME.hand_shuffle_animating = active
	end
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

local function park_card(card, x, y, r)
	card.T.x = x
	card.T.y = y
	card.T.r = r
	if card.VT then
		card.VT.x = x
		card.VT.y = y
		card.VT.r = r
	end
	if card.velocity then
		card.velocity.x = 0
		card.velocity.y = 0
		card.velocity.r = 0
	end
end

local function sync_card_transform(card)
	if card.VT then
		card.VT.x = card.T.x
		card.VT.y = card.T.y
		card.VT.r = card.T.r
	end
end

local function animate_card_move(move, delay, duration, lift)
	Scheduler.add{
		mode = "delayed",
		timer = "REAL",
		delay = delay,
		blockable = false,
		func = function()
			local card = move.card
			card.shuffle_hop = true
			park_card(card, move.sx, move.sy, move.sr)

			local started = G.TIMERS.REAL
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
					card.T.y = move.sy + (move.ty - move.sy) * e - lift * math.sin(math.pi * u)
					card.T.r = move.sr + (move.tr - move.sr) * e
					sync_card_transform(card)
					if u >= 1 then
						card.T.x = move.tx
						card.T.y = move.ty
						card.T.r = move.tr
						sync_card_transform(card)
						card.shuffle_hop = nil
						return true
					end
				end,
			}
			return true
		end,
	}
end

function M.animate(hand, on_complete)
	if animating or not hand or #hand.cards < 2 then
		if on_complete then on_complete() end
		return
	end

	if not (G.TIMELINE and G.TIMELINE.enqueue) then
		hand:shuffle("hand_shuffle")
		hand:relayout()
		hand:hard_set_cards()
		if on_complete then on_complete() end
		return
	end

	local before = capture_layout(hand)
	hand:shuffle("hand_shuffle")
	if hand.set_ranks then
		hand:set_ranks()
	end
	hand:relayout()

	local moves = {}
	for _, card in ipairs(hand.cards) do
		local start = before[card]
		if start then
			local tx = card.T.x
			local ty = card.T.y
			local tr = card.T.r or 0
			if math.abs(start.x - tx) > 0.005 or math.abs(start.y - ty) > 0.005 then
				moves[#moves + 1] = {
					card = card,
					sx = start.x,
					sy = start.y,
					sr = start.r,
					tx = tx,
					ty = ty,
					tr = tr,
					order = tx,
				}
			end
		end
	end

	if #moves == 0 then
		if on_complete then on_complete() end
		return
	end

	table.sort(moves, function(a, b)
		return a.order < b.order
	end)

	set_animating(true)
	if play_sfx then
		play_sfx("hover_card", 0.9, 0.38)
	end

	local lift = lift_height()
	for i, move in ipairs(moves) do
		animate_card_move(move, (i - 1) * STAGGER, SHUFFLE_DURATION, lift)
	end

	local tail = (#moves - 1) * STAGGER + SHUFFLE_DURATION + 0.04
	Scheduler.add{
		mode = "delayed",
		timer = "REAL",
		delay = tail,
		blocking = true,
		func = function()
			for _, card in ipairs(hand.cards) do
				card.shuffle_hop = nil
			end
			hand:relayout()
			hand:snap_VT()
			hand:hard_set_cards()
			set_animating(false)
			if on_complete then on_complete() end
			return true
		end,
	}
end

return M
