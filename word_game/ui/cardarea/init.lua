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
local selection = require("word_game.ui.cardarea.selection")
local relayout_mod = require("word_game.ui.cardarea.relayout")
local chrome = require("word_game.ui.cardarea.chrome")

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
	return selection.can_select(self, card, TYPE_HANDLERS)
end

function CardArea:add_selection(card, silent)
	return selection.add_selection(self, card, silent, TYPE_HANDLERS)
end

function CardArea:remove_selection(card, force)
	return selection.remove_selection(self, card, force)
end

function CardArea:clear_selection()
	return selection.clear_selection(self)
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
	if self == G.discard and WORD_GAME and WORD_GAME.TableDiscard
		and WORD_GAME.TableDiscard.uses_table_draw()
		and not (G.ARGS and G.ARGS.table_discard_board_draw) then
		return
	end

	self.ARGS.invisible_area_types = self.ARGS.invisible_area_types or {discard=1, perk=1, usable=1, title = 1, title_2 = 1, placement=1, shelf=1}
	if self.ARGS.invisible_area_types[self.config.type] or
		(self.config.type == 'deck' and self ~= G.deck) then
	else
		chrome.draw_chrome(self)
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

function CardArea:relayout()
	relayout_mod.relayout(self, face_down_in_pile)
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
