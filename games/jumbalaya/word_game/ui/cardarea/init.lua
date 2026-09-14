--[[
	word_game/ui/cardarea/init.lua - `CardPile`: a region that owns and lays out `Card` instances.

	One class, many roles: `self.config.type` (e.g. 'hand', 'deck',
	'discard', 'shop', 'placement', 'usable', 'perk', 'title')
	controls almost all per-instance behaviour - drag rules (`set_ranks`),
	layout math (`relayout`), draw ordering (`draw`), and selection rules.
	When adding a new area type, search for the existing
	`self.config.type ==` branches across this file first, since behaviour
	for a type is usually spread across several methods rather than
	centralized.
]]


local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local hand = require("word_game.ui.cardarea.hand")
local deck = require("word_game.ui.cardarea.deck")
local discard = require("word_game.ui.cardarea.discard")
local placement = require("word_game.ui.cardarea.placement")
local shop = require("word_game.ui.cardarea.shop")
local title = require("word_game.ui.cardarea.title")
local selection = require("word_game.ui.cardarea.selection")
local relayout_mod = require("word_game.ui.cardarea.relayout")
local chrome = require("word_game.ui.cardarea.chrome")
local lifecycle = require("word_game.ui.cardarea.lifecycle")
local facade = require("word_game.ui.facade")

local TYPE_HANDLERS = {
	hand = hand,
	deck = deck,
	discard = discard,
	placement = placement,
	shop = shop,
	usable = shop,
	title_2 = shop,
	title = title,
	perk = title,
}

--- @class (partial) CardPile : EaseNode
--- @field cards Card[] list of Card instances currently in this area, in display order
--- @field selected Card[] subset of `cards` currently selected/selected
--- @field config table per-instance behaviour config; see `config.type` above
--- @field children { area_uibox: table|nil, view_deck: table|nil, [string]: any }
---@overload fun(...): CardPile
--- @field emplace fun(self: CardPile, card: Card, location: string|nil, stay_flipped: boolean|nil)
--- @field set_ranks fun(self: CardPile)
--- @field relayout fun(self: CardPile)
--- @field remove_card fun(self: CardPile, card: Card|nil, discarded_only: boolean|nil): Card|nil
--- @field remove_selection fun(self: CardPile, card: Card, force: boolean|nil)
--- @field can_select fun(self: CardPile, card: Card): boolean
--- @field add_selection fun(self: CardPile, card: Card, silent: boolean|nil)
--- @field clear_selection fun(self: CardPile)
--- @field sort fun(self: CardPile, method: string|nil)
--- @field shuffle fun(self: CardPile, _seed: string|nil)
--- @field hard_set_cards fun(self: CardPile)
--- @field draw_card_from fun(self: CardPile, area: CardPile, stay_flipped: boolean|nil, discarded_only: boolean|nil): boolean|nil
--- @field save fun(self: CardPile): table|nil
--- @field load fun(self: CardPile, cardAreaTable: table)
CardPile = EaseNode:derive("CardPile")

local function table_board()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
end

local function face_down_in_pile(card)
	if table_board() then return end
	if card.facing == 'front' then
		card:flip()
	end
end

local function draw_card_layer(card, layer)
	if not card then return end
	if runtime().INPUT.dragging.target ~= card and not (WORD_GAME_UI.CardInspect and WORD_GAME_UI.CardInspect.is(card)) then
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
---   `card_w` (number, default `runtime().CARD_W`) - card width override;
---   `sort` (string, default 'desc') - default `CardPile:sort` method.
function CardPile:construct(X, Y, W, H, config)
	EaseNode.construct(self, X, Y, W, H)

	self.states.drag.can = false
	self.states.hover.can = false
	self.states.click.can = false


	config = config or {}
	self.config = config
	self.card_w = config.card_w or runtime().CARD_W
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

	if getmetatable(self) == CardPile then
		table.insert(runtime().LIVE.CARDPILE, self)
	end
end

function CardPile:emplace(card, location, stay_flipped)
	lifecycle.emplace(self, card, location, stay_flipped)
end

function CardPile:remove_card(card, discarded_only)
	return lifecycle.remove_card(self, card, discarded_only, type_handler)
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
function CardPile:can_select(card)
	return selection.can_select(self, card, TYPE_HANDLERS)
end

function CardPile:add_selection(card, silent)
	return selection.add_selection(self, card, silent, TYPE_HANDLERS)
end

function CardPile:remove_selection(card, force)
	return selection.remove_selection(self, card, force)
end

function CardPile:clear_selection()
	return selection.clear_selection(self)
end

--- Assigns each card's `slot` (its 1-based index/position) and sets
--- per-card drag/collide/click ability based on this area's type - e.g. only
--- the top deck card is draggable, 'shop'/'usable' cards can't be dragged
--- once placed.
function CardPile:set_ranks()
	local handler = type_handler(self)
	for k, card in ipairs(self.cards) do
		card.slot = k
		card.states.collide.can = true
		if handler and handler.set_card_ranks then
			handler.set_card_ranks(self, k, card)
		else
			card.states.drag.can = true
		end
		if WORD_GAME_UI.FirstPlayTutorial and WORD_GAME_UI.FirstPlayTutorial.is_active()
			and WORD_GAME_UI.FirstPlayTutorial.is_active() then
			card.states.drag.can = false
		elseif card.states.drag.can then
			card.states.hover.can = true
			card.states.collide.can = true
			card.under_overlay = false
		end
	end
end

--- @param dt number seconds since last frame
function CardPile:move(dt)
	EaseNode.move(self, dt)
	self:relayout()
end

--- @param dt number seconds since last frame
function CardPile:update(dt)
	if self == runtime().dealt_letters then
		for _, v in ipairs(self.cards) do
			if v.ability.forced_selection and not self.selected[1] then
				self:add_selection(v)
			end
		end
	end
	deck.update(self, dt)
	discard.update(self, dt)
	--Check and see if controller is being used
	if runtime().INPUT.HID.controller and self ~= runtime().dealt_letters then self:clear_selection() end
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
function CardPile:draw()
	if not self.states.visible then return end
	if not self.cards then return end
	if runtime().VIEWING_DECK and (self==runtime().draw_pile or self==runtime().dealt_letters) then return end

	if not chrome.skip_chrome(self) then
		chrome.draw_chrome(self)
	end

	placement.draw_shadows(self)

	self:draw_boundingrect()
	track_hit_target(self)

	self.ARGS.draw_layers = self.ARGS.draw_layers or self.config.draw_layers or {'shadow', 'card'}
	for _, v in ipairs(self.ARGS.draw_layers) do
		deck.draw_layer(self, v, draw_card_layer)
		discard.draw_layer(self, v, draw_card_layer)
		placement.draw_layer(self, v, draw_card_layer)
		shop.draw_layer(self, v, draw_card_layer)
		title.draw_layer(self, v, draw_card_layer)
		hand.draw_layer(self, v, draw_card_layer)
	end
end

function CardPile:relayout()
	relayout_mod.relayout(self, face_down_in_pile)
end

--- Immediately (no tween) sets this area's transform and repositions/snaps
--- its cards to match, bypassing the normal smoothed movement.
function CardPile:hard_set_T(X, Y, W, H)
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
function CardPile:hard_set_cards()
	if not self.cards then return end
	for _, card in ipairs(self.cards) do
		card:hard_set_T()
		card:calculate_parallax()
	end
end

function CardPile:shuffle(_seed)
	lifecycle.shuffle(self, _seed)
end

function CardPile:sort(method)
	lifecycle.sort(self, method)
end

function CardPile:draw_card_from(area, stay_flipped, discarded_only)
	return lifecycle.draw_card_from(self, area, stay_flipped, discarded_only)
end

--- Click handler for area-level clicks (not individual cards) - currently
--- only meaningful for the deck (opens deck info) and opponent deck
--- (triggers opponent draw).
function CardPile:click()
	if self == runtime().draw_pile then
		if WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.uses_table_draw() then
			WORD_GAME_UI.TableDeck.show_info()
		end
	end
end

function CardPile:release(dragged)
	local handler = type_handler(self)
	if handler and handler.release then
		handler.release(self, dragged)
	end
end

function CardPile:save()
	return lifecycle.save(self)
end

function CardPile:load(cardAreaTable)
	lifecycle.load(self, cardAreaTable)
end

function CardPile:remove()
	lifecycle.remove(self, type_handler)
end

return CardPile
