--[[
	word_game/ui/cardarea/init.lua - `CardArea`: a region that owns and lays out `Card` instances.

	One class, many roles: `self.config.type` (e.g. 'hand', 'deck',
	'discard', 'shop', 'placement', 'usable', 'perk', 'title')
	controls almost all per-instance behaviour - drag rules (`set_ranks`),
	layout math (`relayout`), draw ordering (`draw`), and selection rules.
	When adding a new area type, search for the existing
	`self.config.type ==` branches across this file first, since behaviour
	for a type is usually spread across several methods rather than
	centralized.
]]

local hand = require("word_game.ui.cardarea.hand")
local deck = require("word_game.ui.cardarea.deck")
local discard = require("word_game.ui.cardarea.discard")
local placement = require("word_game.ui.cardarea.placement")

local TYPE_HANDLERS = {
	hand = hand,
	deck = deck,
	discard = discard,
	placement = placement,
}

--- @class (partial) CardArea : EaseNode
--- @field cards Card[] list of Card instances currently in this area, in display order
--- @field selected Card[] subset of `cards` currently selected/selected
--- @field config table per-instance behaviour config; see `config.type` above
--- @field children { area_uibox: LayoutView|nil, view_deck: LayoutView|nil, [string]: any }
---@overload fun(...): CardArea
--- @field emplace fun(self: CardArea, card: Card, location: string|nil, stay_flipped: boolean|nil)
--- @field set_ranks fun(self: CardArea)
--- @field relayout fun(self: CardArea)
--- @field remove_card fun(self: CardArea, card: Card|nil, discarded_only: boolean|nil): Card|nil
--- @field remove_selection fun(self: CardArea, card: Card, force: boolean|nil)
--- @field can_select fun(self: CardArea, card: Card): boolean
--- @field add_selection fun(self: CardArea, card: Card, silent: boolean|nil)
--- @field clear_selection fun(self: CardArea)
--- @field sort fun(self: CardArea, method: string|nil)
--- @field shuffle fun(self: CardArea, _seed: string|nil)
--- @field hard_set_cards fun(self: CardArea)
--- @field draw_card_from fun(self: CardArea, area: CardArea, stay_flipped: boolean|nil, discarded_only: boolean|nil): boolean|nil
--- @field save fun(self: CardArea): table|nil
--- @field load fun(self: CardArea, cardAreaTable: table)
CardArea = EaseNode:derive("CardArea")

local function table_board()
	return G.STATE == G.STATES.TABLE_BOARD
end

local function face_down_in_pile(card)
	if table_board() then return end
	if card.facing == 'front' then
		card:flip()
	end
end

local function draw_card_layer(card, layer)
	if not card then return end
	if G.INPUT.dragging.target ~= card and not (WORD_GAME and WORD_GAME.CardInspect and WORD_GAME.CardInspect.is(card)) then
		card:draw(layer)
	end
end

local function type_handler(self)
	return TYPE_HANDLERS[self.config.type]
end

--Kind methods

--- @param config table|nil see field comments below; notable keys:
---   `type` (string, default 'deck') - behaviour selector, see file header;
---   `selection_limit` (number, default 5) - max cards selectable at once;
---   `card_limit` (number, default 52) - max cards this area can hold;
---   `card_w` (number, default `G.CARD_W`) - card width override;
---   `sort` (string, default 'desc') - default `CardArea:sort` method.
function CardArea:construct(X, Y, W, H, config)
	EaseNode.construct(self, X, Y, W, H)

	self.states.drag.can = false
	self.states.hover.can = false
	self.states.click.can = false


	config = config or {}
	self.config = config
	self.card_w = config.card_w or G.CARD_W
	self.cards = {}
	self.children = {}
	self.selected = {}
	self.config.selected_limit = config.selection_limit or 5
	self.config.card_limit = config.card_limit or 52
	self.config.temp_limit = self.config.card_limit
	self.config.card_count = 0
	self.config.type = config.type or 'deck'
	self.config.sort = config.sort or 'desc'
	self.config.lr_padding = config.lr_padding or 0.1
	self.shuffle_amt = 0

	if getmetatable(self) == CardArea then
		table.insert(G.LIVE.CARDAREA, self)
	end
end

--- Inserts `card` into this area (front if `location == 'front'` or this is
--- a 'deck', otherwise appended to the back), flips it face-up unless it
--- should stay flipped, re-ranks and re-lays-out cards, and fires
--- deck/companion-related unlock checks.
--- @param card table the Card instance to add
--- @param location string|nil 'front' to insert at index 1
--- @param stay_flipped boolean|nil if true, don't auto-flip a face-down card
function CardArea:emplace(card, location, stay_flipped)
	if table_board() and card and card.bonus_card and (self == G.hand or self == G.deck) then
		local snap = require("word_game.board.snap")
		local origin_slot, origin_insert
		if WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.slot_for_card then
			origin_slot, origin_insert = WORD_GAME.Jumble.slot_for_card(card)
		end
		snap.restore_bonus_card(G.placement_table, card, origin_slot, origin_insert)
		return
	end
	if location == 'front' or self.config.type == 'deck' then
		table.insert(self.cards, 1, card)
	else
		self.cards[#self.cards+1] = card
	end
	if table_board() then
		-- Pile art comes from the back sprite. Cards stay face-up and lerp into place.
		if self == G.hand and WORD_GAME and WORD_GAME.Deck and WORD_GAME.Deck.reveal_in_hand then
			WORD_GAME.Deck.reveal_in_hand(card)
		end
	elseif card.facing == 'back' and self.config.type ~= 'discard' and self.config.type ~= 'deck' and not stay_flipped then
		card:flip()
	elseif self == G.hand and stay_flipped then
		card.ability.wheel_flipped = true
	end

	-- The deck pile is unbounded: overfilling just raises its own limit.
	if self == G.deck and #self.cards > self.config.card_limit then
		self.config.card_limit = #self.cards
	end

	card:set_card_area(self)
	self:set_ranks()
	self:relayout()

end

--- Removes and returns a card from this area. If `card` isn't given, removes
--- the "natural" card to draw from for this area type (top of deck/discard,
--- or first card otherwise), optionally restricted to already-discarded cards.
--- @param card table|nil specific card to remove; if nil, an implicit choice is made
--- @param discarded_only boolean|nil if true (and `card` is nil), only consider discarded cards
--- @return table|nil card the removed card, or nil if none matched
function CardArea:remove_card(card, discarded_only)
	if not self.cards then return end

	local candidates = self.cards
	if discarded_only then
		candidates = {}
		for _, candidate in ipairs(self.cards) do
			if candidate.ability and candidate.ability.discarded then
				candidates[#candidates + 1] = candidate
			end
		end
	end

	-- Piles draw from the top; rows take the front.
	if card == nil and (self.config.type == 'discard' or self.config.type == 'deck') then
		card = candidates[#candidates]
	elseif card == nil then
		card = candidates[1]
	end

	if not card then
		self:set_ranks()
		return
	end
	for i = #self.cards,1,-1 do
		if self.cards[i] == card then
			local handler = type_handler(self)
			if handler and handler.on_remove_card then
				handler.on_remove_card(self, card)
			end
			card:remove_from_area()
			table.remove(self.cards, i)
			self:remove_selection(card, true)
			break
		end
	end
	self:set_ranks()
	return card
end

-- ============ Selection & Highlighting ============
-- "Highlighted" cards are the player's current selection within an area
-- (e.g. cards picked to play, companions picked to sell/reorder).
-- `config.selected_limit` caps how many can be selected at once.

--- Whether cards in this area are allowed to be selected at all, given the
--- current input device. InputController input restricts selecting to hand
--- cards only (no companion/usable/shop multi-select via d-pad).
--- @param card table the card being considered (currently unused, kept for API shape)
--- @return boolean can_select
function CardArea:can_select(card)
	local handler = type_handler(self)
	if handler and handler.can_select then
		if handler.can_select(self, card) then
			return true
		end
	end
	if G.INPUT.HID.controller then
		return false
	else
		if self.config.type == 'usable' or
			(self.config.type == 'shop' and self.config.selected_limit > 0)
		then
				return true
		end
	end
	return false
end

--- Adds `card` to `self.selected`, with type-specific eviction rules once
--- the limit is reached:
--- - 'shop': single-select, always evicts the previous pick.
--- - 'placement'/'usable': evicts the oldest pick (self.selected[1]) once at the limit.
--- - everything else (including 'hand'): silently refuses
---   to add once at `config.selected_limit` - the player must deselect
---   first (see `remove_selection`).
--- @param card table card to set_selected
--- @param silent boolean|nil if true, skip the selection sound effect
function CardArea:add_selection(card, silent)
	local handler = type_handler(self)
	if handler and handler.add_selection then
		return handler.add_selection(self, card, silent)
	end

	-- Make room under this area's eviction policy first...
	if self.config.type == 'shop' then
		-- Single-select: the new pick always evicts the previous one.
		if self.selected[1] then self:remove_selection(self.selected[1]) end
	elseif self.config.type == 'usable' then
		if #self.selected >= self.config.selected_limit then
			self:remove_selection(self.selected[1]) -- evict the oldest
		end
	elseif #self.selected >= self.config.selected_limit then
		return -- hand and other rows refuse silently; deselect manually
	end

	-- ...then every area appends identically.
	self.selected[#self.selected + 1] = card
	card:set_selected(true)
	if not silent then play_sfx('card_slide1') end
end

--- Removes `card` from `self.selected`. Cards marked
--- `ability.forced_selection` in the hand can't be deselected unless
--- `force` is true (used for e.g. debuffed cards that must stay selected).
--- @param card table card to deselect
--- @param force boolean|nil bypass the forced-selection protection
function CardArea:remove_selection(card, force)
	if (not force) and  card and card.ability.forced_selection and self == G.hand then return end
	for i = #self.selected,1,-1 do
		if self.selected[i] == card then
			table.remove(self.selected, i)
			break
		end
	end
	card:set_selected(false)
end

--- Clears the entire selection, except cards with `ability.forced_selection`
--- in the hand (mirrors the protection in `remove_selection`).
function CardArea:clear_selection()
	for i = #self.selected, 1, -1 do
		local card = self.selected[i]
		local pinned_by_effect = self == G.hand and card.ability.forced_selection
		if not pinned_by_effect then
			card:set_selected(false)
			table.remove(self.selected, i)
		end
	end
end

--- Assigns each card's `slot` (its 1-based index/position) and sets
--- per-card drag/collide/click ability based on this area's type - e.g. only
--- the top deck card is draggable, 'shop'/'usable' cards can't be dragged
--- once placed.
function CardArea:set_ranks()
	local handler = type_handler(self)
	for k, card in ipairs(self.cards) do
		card.slot = k
		card.states.collide.can = true
		if handler and handler.set_card_ranks then
			handler.set_card_ranks(self, k, card)
		elseif self.config.type == 'shop' or self.config.type == 'usable' then
			card.states.drag.can = false
		else
			card.states.drag.can = true
		end
		if WORD_GAME and WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.allows_card_drag
			and not WORD_GAME.PlayerHost.allows_card_drag(self) then
			card.states.drag.can = false
		elseif card.states.drag.can then
			card.states.hover.can = true
			card.states.collide.can = true
			card.under_overlay = false
		end
	end
end

--- @param dt number seconds since last frame
function CardArea:move(dt)
	EaseNode.move(self, dt)
	self:relayout()
end

--- @param dt number seconds since last frame
function CardArea:update(dt)
	if self == G.hand then
		for k, v in pairs(self.cards) do
			if v.ability.forced_selection and not self.selected[1] then
				self:add_selection(v)
			end
		end
	end
	deck.update(self, dt)
	discard.update(self, dt)
	--Check and see if controller is being used
	if G.INPUT.HID.controller and self ~= G.hand then self:clear_selection() end
	self.config.temp_limit = math.max(#self.cards, self.config.card_limit)
	self.config.card_count = #self.cards
end

--- Draws this area's optional card-count UI badge, then draws its cards.
--- Draw order/grouping is type-specific (see the `self.config.type ==`
--- branches below): decks draw back-to-front skipping most middle cards for
--- performance, placement/usable/shop areas draw non-selected cards
--- before selected ones (so selected cards render on top), discard only
--- bothers drawing cards that have visibly animated away from the pile
--- center, and hand/title/perk areas just draw in order.
function CardArea:draw()
	if not self.states.visible then return end
	if not self.cards then return end
	if G.VIEWING_DECK and (self==G.deck or self==G.hand) then return end

	self.ARGS.invisible_area_types = self.ARGS.invisible_area_types or {discard=1, perk=1, usable=1, title = 1, title_2 = 1, placement=1, shelf=1}
	if self.ARGS.invisible_area_types[self.config.type] or
		(self.config.type == 'deck' and self ~= G.deck) then
	else
		if self == G.hand and self.children.area_uibox and not self.config.hide_card_count then
			self.children.area_uibox:remove()
			self.children.area_uibox = nil
		end
		if self == G.hand then
			self.config.hide_card_count = true
		end
		if not self.children.area_uibox then
				local show_count = self ~= G.shop_perks and self ~= G.hand
				local placement_area = G.placement_table and G.placement_table.area
				local card_count = show_count and {n=G.UI.ROW, config={align = self == placement_area and 'cl' or 'cr', padding = 0.03, no_fill = true}, nodes={
					{n=G.UI.BOX, config={w = 0.1,h=0.1}},
					{n=G.UI.TEXT, config={ref_table = self.config, ref_value = 'card_count', scale = 0.3, colour = G.C.WHITE}},
					{n=G.UI.TEXT, config={text = '/', scale = 0.3, colour = G.C.WHITE}},
					{n=G.UI.TEXT, config={ref_table = self.config, ref_value = 'card_limit', scale = 0.3, colour = G.C.WHITE}},
					{n=G.UI.BOX, config={w = 0.1,h=0.1}}
				}} or nil

				self.children.area_uibox = LayoutView{
					definition =
						{n=G.UI.ROOT, config = {align = 'cm', colour = G.C.CLEAR}, nodes={
							{n=G.UI.ROW, config={minw = self.T.w,minh = self.T.h,align = "cm", padding = 0.1, mid = true, r = 0.1, colour = self ~= G.shop_perks and {0,0,0,0.1} or nil, ref_table = self}, nodes={
								self == G.shop_perks and
								{n=G.UI.COLUMN, config={align = "cm", paddin = 0.1, func = 'shop_voucher_empty', visible = false}, nodes={
									{n=G.UI.ROW, config={align = "cm"}, nodes={
										{n=G.UI.TEXT, config={text = 'DEFEAT', scale = 0.6, colour = G.C.WHITE}}
									}},
									{n=G.UI.ROW, config={align = "cm"}, nodes={
										{n=G.UI.TEXT, config={text = 'BOSS WORD', scale = 0.4, colour = G.C.WHITE}}
									}},
									{n=G.UI.ROW, config={align = "cm"}, nodes={
										{n=G.UI.TEXT, config={text = 'TO RESTOCK', scale = 0.4, colour = G.C.WHITE}}
									}},
								}} or nil,
							}},
							card_count
						}},
					config = { align = 'cm', offset = {x=0,y=0}, major = self, parent = self}
				}
			end
		local skip_pad = self == G.deck and WORD_GAME and WORD_GAME.TableDeck
			and WORD_GAME.TableDeck.uses_table_draw()
		if not skip_pad then
			self.children.area_uibox:draw()
		end
	end

	placement.draw_shadows(self)

	self:draw_boundingrect()
	track_hit_target(self)

	self.ARGS.draw_layers = self.ARGS.draw_layers or self.config.draw_layers or {'shadow', 'card'}
	for k, v in ipairs(self.ARGS.draw_layers) do
		deck.draw_layer(self, v, draw_card_layer)
		discard.draw_layer(self, v, draw_card_layer)
		placement.draw_layer(self, v, draw_card_layer)

		if self.config.type == 'usable' or self.config.type == 'shop' or self.config.type == 'title_2' then
			for i = 1, #self.cards do
				if self.cards[i] ~= G.INPUT.focused.target then
					if not self.cards[i].selected then
						draw_card_layer(self.cards[i], v)
					end
				end
			end
			for i = 1, #self.cards do
				if self.cards[i] ~= G.INPUT.focused.target then
					if self.cards[i].selected then
						draw_card_layer(self.cards[i], v)
					end
				end
			end
		end

		hand.draw_layer(self, v, draw_card_layer)

		if self.config.type == 'title' or self.config.type == 'perk' then
			for i = 1, #self.cards do
				if self.cards[i] ~= G.INPUT.focused.target or self == G.hand then
					draw_card_layer(self.cards[i], v)
				end
			end
		end
	end
end

------------------------------------------------------------------------------
-- Slot math
--
-- Every layout below places cards by answering three questions: which slot a
-- card occupies along the row, how far that slot lifts selected cards, and how
-- much idle tilt/bob the row carries. These helpers centralise that math so
-- each layout only states its own parameters.
------------------------------------------------------------------------------

--- Horizontal progress of slot `slot` when `count` cards share a row built for
--- `max_slots`: cards compress toward the middle as count exceeds capacity.
local function row_progress(slot, count, max_slots)
	local span = math.max(max_slots - 1, 1)
	return (slot - 1) / span - 0.5 * (count - max_slots) / span
end

--- X coordinate for the card in slot `k of count`, optionally compressed into
--- a narrower `span_width` centred inside the area (used by the perk fan).
local function slot_x(area, card, k, count, max_slots, span_width)
	local width = span_width or area.T.w
	local x = area.T.x + (width - area.card_w) * row_progress(k, count, max_slots)
		+ 0.5 * (area.card_w - card.T.w)
	if span_width then x = x + (area.T.w - width) / 2 end
	return x
end

--- Evenly spaced variant: every card owns an equal slice of the row.
local function even_x(area, card, k, count)
	if count > 1 then
		return area.T.x + (area.T.w - area.card_w) * ((k - 1) / (count - 1)) + 0.5 * (area.card_w - card.T.w)
	end
	return area.T.x + area.T.w / 2 - area.card_w / 2 + 0.5 * (area.card_w - card.T.w)
end

--- Vertical offset for selected cards; `scale` shrinks the lift on shorter rows.
local function selection_lift(card, scale)
	if card.selected then return G.HIGHLIGHT_H * (scale or 1) end
	return 0
end

--- Slow breathing tilt shared by fanned rows.
local function fan_tilt(k, count, amplitude, phase_x, phase_y)
	local lean = amplitude * (-count / 2 - 0.5 + k) / count
	local wobble = 0.02 * math.sin(2 * G.TIMERS.REAL + phase_x + (phase_y or 0))
	return lean + wobble
end

--- Gentle vertical bob keyed off the card's own position.
local function row_bob(x)
	return 0.03 * math.sin(0.666 * G.TIMERS.REAL + x)
end

-- Parallax drift keeps stacked shadow layers from looking glued to the row.
local function apply_parallax(card)
	card.T.x = card.T.x + card.shadow_parallax.x / 30
end

-- Sorts the row back into left-to-right order after positioning moved cards.
local function sort_by_left_edge(cards)
	table.sort(cards, function(a, b) return a.T.x + a.T.w / 2 < b.T.x + b.T.w / 2 end)
end

--- Positions every card in `self.cards` (writes `card.T.x/y/r` directly)
--- according to this area's `config.type`. Skipped entirely while a deck
--- preview overlay (`G.view_deck`) is open for hand/deck/discard/play areas.
function CardArea:relayout()
	if not self.cards then return end
	if (self == G.hand or self == G.deck or self == G.discard) and G.view_deck and G.view_deck[1] and G.view_deck[1].cards then return end

	deck.relayout(self)
	hand.relayout(self)

	local count = #self.cards
	local layout = self.config.type

	if layout == 'discard' then
		for k, card in ipairs(self.cards) do
			face_down_in_pile(card)
			if not card.states.drag.is then
				card.T.x = self.T.x + (self.T.w - card.T.w) * card.discard_pos.x
				card.T.y = self.T.y + (self.T.h - card.T.h) * card.discard_pos.y
				card.T.r = card.discard_pos.r
			end
		end
	end

	-- Single-card perk rows fan out exactly like title rows.
	if layout == 'title' or (layout == 'perk' and count == 1) then
		for k, card in ipairs(self.cards) do
			if not card.states.drag.is then
				local max_slots = math.max(count, self.config.temp_limit)
				card.T.r = fan_tilt(k, count, 0.2, card.T.x)
				card.T.x = slot_x(self, card, k, count, max_slots)
				card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 - selection_lift(card)
					+ row_bob(card.T.x)
					+ math.abs(0.5 * (-count / 2 + k - 0.5) / count)
					- (count > 1 and 0.2 or 0)
				apply_parallax(card)
			end
		end
		sort_by_left_edge(self.cards)
	end

	if layout == 'perk' and count > 1 then
		local span_width = math.max(self.T.w, 3.2)
		for k, card in ipairs(self.cards) do
			if not card.states.drag.is then
				local max_slots = math.max(count, self.config.temp_limit)
				local side = (k % 2 == 1) and -1 or 1 -- alternate cards zig-zag
				card.T.r = fan_tilt(k, count, 0.2, card.T.x, card.T.y) + side * 0.08
				card.T.x = slot_x(self, card, k, count, max_slots, span_width) - side * 0.27
				card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 - selection_lift(card)
					+ row_bob(card.T.x)
					+ math.abs(0.5 * (-count / 2 + k - 0.5) / count)
					- (count > 1 and 0.2 or 0)
				apply_parallax(card)
			end
		end
		table.sort(self.cards, function(a, b) return a.ability.order < b.ability.order end)
	end

	if layout == 'shop' then
		for k, card in ipairs(self.cards) do
			if not card.states.drag.is then
				local max_slots = math.max(count, self.config.temp_limit)
				card.T.r = 0
				card.T.x = slot_x(self, card, k, count, max_slots)
				if self.config.card_limit == 1 then
					card.T.x = card.T.x + 0.5 * (self.T.w - card.T.w)
				end
				card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 - selection_lift(card)
				apply_parallax(card)
			end
		end
		sort_by_left_edge(self.cards)
	end

	if layout == 'title_2' then
		for k, card in ipairs(self.cards) do
			if not card.states.drag.is then
				card.T.r = fan_tilt(k, count, 0.1, card.T.x)
				if count > 2 or (count > 1 and self.config.spread) then
					card.T.x = even_x(self, card, k, count)
				elseif count > 1 then
					card.T.x = self.T.x + (self.T.w - self.card_w) * ((k - 0.5) / count) + 0.5 * (self.card_w - card.T.w)
				else
					card.T.x = even_x(self, card, k, count)
				end
				card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 - selection_lift(card, 0.5)
					+ row_bob(card.T.x)
				apply_parallax(card)
			end
		end
		-- Pinned cards hold their neighbourhood instead of drifting to the edge.
		table.sort(self.cards, function(a, b)
			return a.T.x + a.T.w / 2 - 100 * (a.pinned and a.sort_id or 0)
				< b.T.x + b.T.w / 2 - 100 * (b.pinned and b.sort_id or 0)
		end)
	end

	if layout == 'usable' then
		for k, card in ipairs(self.cards) do
			if not card.states.drag.is then
				card.T.x = even_x(self, card, k, count)
				card.T.y = self.T.y + self.T.h / 2 - card.T.h / 2 - selection_lift(card)
					+ (not card.selected and 0.05 * math.sin(3.332 * G.TIMERS.REAL + card.T.x) or 0)
				apply_parallax(card)
			end
		end
		sort_by_left_edge(self.cards)
	end

	placement.relayout(self)

	for k, card in ipairs(self.cards) do
		card.slot = k
	end
	if self.children.view_deck then
		self.children.view_deck:set_role{major = self.cards[1] or self}
	end
end

--- Immediately (no tween) sets this area's transform and repositions/snaps
--- its cards to match, bypassing the normal smoothed movement.
function CardArea:hard_set_T(X, Y, W, H)
	local x = (X or self.T.x)
	local y = (Y or self.T.y)
	local w = (W or self.T.w)
	local h = (H or self.T.h)
	EaseNode.hard_set_T(self,x, y, w, h)
	self:calculate_parallax()
	self:relayout()
	self:hard_set_cards()
end

--- Immediately snaps every card's transform to its current target position
--- (no animation), used after `hard_set_T` or on load.
function CardArea:hard_set_cards()
	if not self.cards then return end
	for k, card in pairs(self.cards) do
		card:hard_set_T()
		card:calculate_parallax()
	end
end

--- Deterministically shuffles `self.cards` using the game's seeded PRNG
--- (`shuffle_seeded`/`advance_seed`), so shuffles are reproducible from a seed
--- rather than using `math.random` directly.
--- @param _seed string|nil shuffle seed suffix (default 'shuffle')
function CardArea:shuffle(_seed)
	shuffle_seeded(self.cards, advance_seed(_seed or 'shuffle'))
	self:set_ranks()
end

--- Sorts `self.cards` in place by the given method (or the last-used one).
--- @param method string|nil one of 'desc'|'asc'|'color desc'|'color asc'|'order'
function CardArea:sort(method)
	self.config.sort = method or self.config.sort
	if self.config.sort == 'desc' then
		table.sort(self.cards, function (a, b) return a:get_nominal() > b:get_nominal() end )
	elseif self.config.sort == 'asc' then
		table.sort(self.cards, function (a, b) return a:get_nominal() < b:get_nominal() end )
	elseif self.config.sort == 'color desc' or self.config.sort == 'suit desc' then
		table.sort(self.cards, function (a, b) return a:get_nominal('color') > b:get_nominal('color') end )
	elseif self.config.sort == 'color asc' or self.config.sort == 'suit asc' then
		table.sort(self.cards, function (a, b) return a:get_nominal('color') < b:get_nominal('color') end )
	elseif self.config.sort == 'order' then
		table.sort(self.cards, function (a, b) return (a.config.card.order or a.config.center.order) < (b.config.card.order or b.config.center.order) end )
	end
end

--- Moves a card from `area` into this area (e.g. deck -> hand). Respects
--- this area's card limit unless it's the deck or hand. Applies
--- "stay flipped" modifier-driven "stay flipped" (face-down draw) rules.
--- @param area table source CardArea
--- @param stay_flipped boolean|nil force the drawn card to stay face-down
--- @param discarded_only boolean|nil only draw from already-discarded cards in `area`
--- @return boolean|nil success true if a card was moved
function CardArea:draw_card_from(area, stay_flipped, discarded_only)
	if area:is_kind(CardArea) then
		if #self.cards < self.config.card_limit or self == G.deck or self == G.hand then
			local card = area:remove_card(nil, discarded_only)
			if card then
				if area == G.discard then
					card.T.r = 0
				end
				self:emplace(card)
				return true
			end
		end
	end
end

--- Click handler for area-level clicks (not individual cards) - currently
--- only meaningful for the deck (opens deck info) and opponent deck
--- (triggers opponent draw).
function CardArea:click()
	if self == G.deck then
		if WORD_GAME and WORD_GAME.TableDeck and WORD_GAME.TableDeck.uses_table_draw() then
			WORD_GAME.TableDeck.show_info()
		end
	end
end

function CardArea:release(dragged)
	local handler = type_handler(self)
	if handler and handler.release then
		handler.release(self, dragged)
	end
end

--- Serializes this area's cards and config for save-game persistence.
--- @return table|nil save_data {cards = {...}, config = self.config}
function CardArea:save()
	if not self.cards then return end
	local cardAreaTable = {
		cards = {},
		config = self.config,
	}
	for i = 1, #self.cards do
		cardAreaTable.cards[#cardAreaTable.cards + 1] = self.cards[i]:save()
	end

	return cardAreaTable
end

--- Restores this area's cards/config from save data produced by `:save()`.
--- Rebuilds every `Card` instance from scratch rather than mutating existing
--- ones.
--- @param cardAreaTable table save data as produced by `CardArea:save`
function CardArea:load(cardAreaTable)

	teardown_tree(self.cards or {})
	self.cards = {}
	teardown_tree(self.children or {})
	self.children = {}
	self.selected = {}

	self.config = cardAreaTable.config

	for i = 1, #cardAreaTable.cards do
		local card = Card(0, 0, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS.letter_base, nil)
		card:load(cardAreaTable.cards[i])
		self.cards[#self.cards + 1] = card
		if card.selected then
			self.selected[#self.selected + 1] = card
		end
		card:set_card_area(self)
	end
	self:set_ranks()
	self:relayout()
	self:hard_set_cards()
end

--- Tears down this area: removes all cards/children, unregisters from
--- `G.LIVE.CARDAREA`, then calls the base `EaseNode:remove`.
function CardArea:remove()
	local handler = type_handler(self)
	if handler and handler.on_remove then
		handler.on_remove(self)
	end
	teardown_tree(self.cards or {})
	self.cards = nil
	teardown_tree(self.children or {})
	self.children = nil
	for k, v in pairs(G.LIVE.CARDAREA) do
		if v == self then
			table.remove(G.LIVE.CARDAREA, k)
		end
	end
	EaseNode.remove(self)
end

return CardArea
