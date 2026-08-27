--[[
	word_game/ui/play_hold_redraw.lua - Hold play button to redraw the entire hand.

	Hold for 5s: yellow ring drains clockwise from 12 o'clock, then hand cards
	slide down off screen and 7 new cards deal in one at a time from the deck.
]]
local Scheduler = require "app.effects.scheduler"


local M = {}

M.HOLD_DURATION = 5.0
M.CLICK_BLOCK = 0.18
M.DISCARD_STAGGER = 0.05
M.RING_WIDTH = 3.5

local hold_t = 0
local holding = false
local block_click = false
local peak_hold_t = 0
local animating = false

local function safe_sound(name, pitch, vol)
	if type(play_sfx) == "function" then
		play_sfx(name, pitch, vol)
	end
end

local function safe_random(seed_key)
	if type(seeded_random) == "function" then
		return seeded_random(seed_key)
	end
	return math.random()
end

local function gameplay_overlays_active()
	if WORD_GAME and WORD_GAME.TradeUI and WORD_GAME.TradeUI.is_open and WORD_GAME.TradeUI.is_open() then
		return true
	end
	return false
end

local function play_button_uie()
	return WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.play_button_uie()
end

local function belongs_to_play_button(node)
	local btn = play_button_uie()
	if not btn or not node then return false end
	if node == btn then return true end
	local n = node
	while n do
		if n == btn then return true end
		if n.config and n.config.id == "hand_play_button" then return true end
		n = n.parent
	end
	return false
end

local function is_pressing_play()
	local btn = play_button_uie()
	if not btn or not btn.states.visible or not btn.config.button then return false end

	local c = G.INPUT
	local press_state = (c and c.pointer_held) or (love.mouse and love.mouse.isDown and love.mouse.isDown(1))
	if not press_state then return false end

	if btn.states.collide and btn.states.collide.is then return true end
	if btn.states.hover and btn.states.hover.is then return true end

	for _, node in ipairs((c and c.collision_list) or {}) do
		if belongs_to_play_button(node) then return true end
	end

	for _, node in ipairs((c and c.nodes_at_cursor) or {}) do
		if belongs_to_play_button(node) then return true end
	end

	local pt = G.POINTER and G.POINTER.T
	if pt and btn.collides_with_point and btn:collides_with_point(pt) then return true end

	return false
end

function M.is_animating()
	return animating
end

function M.is_holding()
	return holding and hold_t > 0
end

function M.hold_progress()
	if M.HOLD_DURATION <= 0 then return 0 end
	return math.min(1, hold_t / M.HOLD_DURATION)
end

function M.can_hold()
	if animating then return false end
	if G.GAME and G.GAME.word_score_animating then return false end
	if G.GAME and G.GAME.hand_redraw_animating then return false end
	if G.GAME and G.GAME.hand_shuffle_animating then return false end
	if G.GAME and G.GAME.placement_recall_animating then return false end
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if gameplay_overlays_active() then return false end
	local btn = play_button_uie()
	return btn and btn.states.visible and btn.config.button ~= nil
end

local function reset_hold()
	holding = false
	hold_t = 0
end

function M.reset()
	reset_hold()
	block_click = false
	peak_hold_t = 0
	animating = false
	if G.GAME and G.GAME.hand_redraw_animating then
		G.GAME.hand_redraw_animating = false
		if WORD_GAME and WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.refresh_card_input then
			WORD_GAME.PlayerHost.refresh_card_input()
		else
			if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
			if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
				G.placement_table.area:set_ranks()
			end
		end
	end
end

local function recall_placement_cards()
	if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.recall_placement_cards then
		WORD_GAME.HandShuffle.recall_placement_cards()
	end
end

local function discard_hand_down(on_complete)
	if not G.TIMELINE then
		if on_complete then on_complete() end
		return 0
	end

	recall_placement_cards()

	local cards_to_discard = {}
	if G.hand and G.hand.cards then
		for _, card in ipairs(G.hand.cards) do
			cards_to_discard[#cards_to_discard + 1] = card
		end
	end

	local n = #cards_to_discard
	if n <= 0 then
		if on_complete then on_complete() end
		return 0
	end

	local target_offscreen_y = (G.ROOM and (G.ROOM.T.y + G.ROOM.T.h) or 11) + 2.5

	for i, card in ipairs(cards_to_discard) do
		Scheduler.add{
			mode = "delayed",
			delay = M.DISCARD_STAGGER * (i - 1),
			func = function()
				if card.area == G.hand then
					G.hand:remove_card(card)
				end
				if card.T then
					card.T.y = target_offscreen_y
					card.T.r = (card.T.r or 0) + (safe_random("redraw_tilt") - 0.5) * 0.25
				end
				if card.pulse then
					card:pulse(0.1, 0.05)
				end
				safe_sound("card_slide1", 0.85 + (i / math.max(1, n)) * 0.2, 0.6)
				return true
			end,
		}
	end

	local tail = (n - 1) * M.DISCARD_STAGGER + 0.35
	Scheduler.add{
		mode = "delayed",
		delay = tail,
		blocking = true,
		func = function()
			for _, card in ipairs(cards_to_discard) do
				if G.deck then
					G.deck:emplace(card)
				end
			end
			if G.deck then
				G.deck:shuffle("play_hold_redraw")
				G.deck:hard_set_T()
			end
			if G.hand then
				G.hand:relayout()
				G.hand:hard_set_cards()
			end
			if on_complete then
				on_complete()
			end
			return true
		end,
	}

	return n
end

local function finish_redraw()
	animating = false
	if G.GAME then
		G.GAME.hand_redraw_animating = false
	end
	block_click = true
	if WORD_GAME and WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.refresh_card_input then
		WORD_GAME.PlayerHost.refresh_card_input()
	else
		if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
		if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
			G.placement_table.area:set_ranks()
		end
	end
	if G.hand and G.hand.relayout then
		G.hand:relayout()
	end
	if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync_visibility then
		WORD_GAME.HandShuffle.sync_visibility()
	end
end

local function trigger_redraw()
	if animating or not M.can_hold() then
		reset_hold()
		return
	end

	animating = true
	block_click = true
	peak_hold_t = M.HOLD_DURATION
	reset_hold()
	if G.GAME then
		G.GAME.hand_redraw_animating = true
	end

	safe_sound("whoosh1", 0.9, 0.75)

	discard_hand_down(function()
		if not (WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.deal_into_hand) then
			finish_redraw()
			return
		end
		WORD_GAME.Deck.deal_into_hand(G.TABLE_HAND_SIZE or 7, finish_redraw)
	end)
end

function M.consume_click()
	if block_click then
		block_click = false
		peak_hold_t = 0
		return true
	end
	if peak_hold_t >= M.CLICK_BLOCK then
		peak_hold_t = 0
		return true
	end
	return false
end

function M.update(dt)
	dt = dt or 0

	if gameplay_overlays_active() then
		reset_hold()
		return
	end

	if animating then
		reset_hold()
		return
	end

	local c = G.INPUT
	local press_state = (c and c.pointer_held) or (love.mouse and love.mouse.isDown and love.mouse.isDown(1))
	if not press_state then
		if peak_hold_t >= M.CLICK_BLOCK then
			block_click = true
		end
		reset_hold()
		return
	end

	if not M.can_hold() or not is_pressing_play() then
		reset_hold()
		return
	end

	if not holding and hold_t <= 0 then
		safe_sound("hover_card", 0.85, 0.35)
	end

	holding = true
	hold_t = hold_t + dt
	peak_hold_t = hold_t
	if hold_t >= M.HOLD_DURATION then
		trigger_redraw()
	end
end

local function draw_arc(cx, cy, radius, start_angle, end_angle, r, g, b, a, width)
	local sweep = end_angle - start_angle
	if sweep <= 0.001 then return end

	local steps = math.max(8, math.ceil(64 * (sweep / (2 * math.pi))))
	if love.graphics.setColor then love.graphics.setColor(r, g, b, a or 1) end
	if love.graphics.setLineWidth then love.graphics.setLineWidth(width) end
	if love.graphics.setLineJoin then love.graphics.setLineJoin("bevel") end
	for i = 0, steps - 1 do
		local a0 = start_angle + sweep * (i / steps)
		local a1 = start_angle + sweep * ((i + 1) / steps)
		love.graphics.line(
			cx + math.cos(a0) * radius,
			cy + math.sin(a0) * radius,
			cx + math.cos(a1) * radius,
			cy + math.sin(a1) * radius
		)
	end
end

local function find_sprite_object(uie)
	if not uie then return nil end
	if uie.config and uie.config.object and uie.config.object.VT then
		return uie.config.object
	end
	for _, child in pairs(uie.children or {}) do
		local found = find_sprite_object(child)
		if found then return found end
	end
	return nil
end

function M.draw()
	if gameplay_overlays_active() then return end
	if not holding or hold_t <= 0 then return end

	local btn = play_button_uie()
	if not btn or not btn.states.visible then return end

	local progress = M.hold_progress()
	local w = (btn.VT.w or 1.25) * (G.TILESIZE or 20)
	local h = (btn.VT.h or 1.25) * (G.TILESIZE or 20)
	local cx, cy = w * 0.5, h * 0.5

	local sprite = find_sprite_object(btn)
	local sprite_w = sprite and sprite.VT and sprite.VT.w and (sprite.VT.w * (G.TILESIZE or 20))
	local radius = (sprite_w and sprite_w > 0 and (sprite_w * 0.5)) or (math.min(w, h) * 0.5)
	local line_w = M.RING_WIDTH

	love.graphics.push()
	if btn.container and btn.translate_container then
		btn:translate_container()
	elseif btn.LayoutView and btn.LayoutView.container and btn.LayoutView.translate_container then
		btn.LayoutView:translate_container()
	elseif G.ROOM and G.ROOM.translate_container then
		G.ROOM:translate_container()
	end

	push_node_transform(btn, 1)
	love.graphics.scale(1 / (G.TILESIZE or 1))

	local a_top = -math.pi * 0.5

	-- Dim background track (represents the lost illumination / ring track)
	draw_arc(cx, cy, radius, a_top, a_top + 2 * math.pi, 0.45, 0.40, 0.15, 0.35, line_w)

	-- The yellow ring loses its illumination border color starting from the 12 o'clock position
	-- and draining clockwise over 5 seconds (progress 0 -> 1).
	-- Illuminated portion runs from (a_top + progress * 2 * pi) to (a_top + 2 * pi).
	if progress < 1.0 then
		local a_start = a_top + progress * 2 * math.pi
		local a_end = a_top + 2 * math.pi

		-- Soft outer yellow halo/glow
		draw_arc(cx, cy, radius, a_start, a_end, 1.0, 0.90, 0.20, 0.45, line_w + 2.5)
		-- Bright yellow illumination border
		draw_arc(cx, cy, radius, a_start, a_end, 1.0, 0.94, 0.12, 1.0, line_w)
		-- Crisp inner set_selected
		draw_arc(cx, cy, radius, a_start, a_end, 1.0, 1.0, 0.65, 0.75, math.max(1, line_w - 1.5))
	end

	love.graphics.pop()
	love.graphics.pop()
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1, 1, 1, 1)
end

return M
