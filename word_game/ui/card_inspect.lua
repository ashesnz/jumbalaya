--[[
	word_game/ui/card_inspect.lua - Hover / click-and-hold to read a letter card.

	Hover or hold without moving: the card scales up in its slot and draws in
	the foreground. Move past a threshold while held: cancel inspect and drag.
]]

local M = {}

M.HOLD_DELAY = 0.22
M.ZOOM_TIME = 0.16
M.MOVE_THRESH = 0.28
M.BASE_SCALE = 0.95
M.PEEK_SCALE = 1.52
M.LIFT = 0

local hold_card = nil
local hold_t = 0
local peek = 0
local peek_card = nil

local function is_letter_card(card)
	if not card or getmetatable(card) ~= Card then return false end
	if card.REMOVED then return false end
	local set = card.ability and card.ability.set
	if set ~= "Default" and set ~= "Enhanced" then return false end
	local area = card.area
	if not area then return false end
	return area == G.hand or (area.config and area.config.type == "placement")
end

local function ease_inout(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t * t * (3 - 2 * t)
end

local function cursor_moved()
	local c = G.INPUT
	if not c or not c.press_state or not c.hover_state then return 0 end
	local a, b = c.press_state.T, c.hover_state.T
	if not a or not b then return 0 end
	local dx, dy = (b.x or 0) - (a.x or 0), (b.y or 0) - (a.y or 0)
	return math.sqrt(dx * dx + dy * dy)
end

local function restore_scale(card)
	if card and not card.REMOVED then
		card.T.scale = M.BASE_SCALE
		card.parallax_shift = nil
		card.inspecting = nil
	end
end

local function apply_visual(card, amount)
	if not card or card.REMOVED then return end
	local e = ease_inout(amount)
	card.T.scale = M.BASE_SCALE + (M.PEEK_SCALE - M.BASE_SCALE) * e
	card.parallax_shift = { x = 0, y = -M.LIFT * e }
	card.inspecting = e > 0.01
end

local function set_peek_card(card)
	if peek_card == card then return end
	if peek_card then
		restore_scale(peek_card)
	end
	peek_card = card
	if card then
		peek = math.max(peek, 0.08)
	else
		peek = 0
	end
end

local function start_drag(card)
	local c = G.INPUT
	if not c or not card or card.REMOVED then return end
	if not card.states.drag.can then return end
	restore_scale(card)
	card.states.drag.is = true
	card:set_offset(c.press_state.T, "Click")
	c.dragging.target = card
	c.dragging.handled = false
	hold_card = nil
	peek_card = nil
	peek = 0
	hold_t = 0
end

local function wanted_card()
	local c = G.INPUT
	if not c then return nil end
	if c.dragging and c.dragging.target then return nil end

	if c.pointer_held and hold_card and not hold_card.REMOVED then
		if cursor_moved() > M.MOVE_THRESH then
			start_drag(hold_card)
			return nil
		end
		if hold_t >= M.HOLD_DELAY then
			return hold_card
		end
		-- Still in the click window: don't peek from a tap.
		return nil
	end

	local hover = c.hovering and c.hovering.target
	if is_letter_card(hover) and not (hover.states and hover.states.drag.is) then
		return hover
	end
	return nil
end

function M.can_inspect(card)
	return is_letter_card(card)
end

function M.is(card)
	return card and peek_card == card and peek > 0.01
end

function M.begin_hold(card)
	if not is_letter_card(card) then return end
	hold_card = card
	hold_t = 0
end

function M.update(dt)
	dt = dt or 0
	local c = G.INPUT
	if c and c.pointer_held and hold_card then
		hold_t = hold_t + dt
	elseif not (c and c.pointer_held) then
		hold_card = nil
		hold_t = 0
	end

	local want = wanted_card()
	if want then
		if peek_card ~= want then
			set_peek_card(want)
			play_sfx("hover_card", 0.95, 0.4)
		end
		peek = math.min(1, peek + dt / M.ZOOM_TIME)
		apply_visual(want, peek)
		return
	end

	if peek_card and peek > 0 then
		peek = math.max(0, peek - dt / (M.ZOOM_TIME * 0.85))
		apply_visual(peek_card, peek)
		if peek <= 0 then
			restore_scale(peek_card)
			peek_card = nil
		end
	end
end

function M.draw_foreground()
	local card = peek_card
	if not card or card.REMOVED or peek <= 0.01 then return end
	if G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target == card then
		return
	end
	love.graphics.push()
	card:translate_container()
	card:draw()
	love.graphics.pop()
end

return M
