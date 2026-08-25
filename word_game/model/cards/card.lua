--[[
	 word_game/model/cards/card.lua - Card class: a letter on the table.

	Extends EaseNode. Extra methods are mixed in from:
	  card_ability.lua  apply_center / edition / seal / deck membership
	  card_visuals.lua  sprites, dissolve, draw
	  card_ui.lua       hover tooltips, click, per-frame update
]]

---@class (partial) Card : EaseNode
---@field ability CardAbility
---@field base table
---@field config table
---@field area CardArea|nil
---@field selected boolean
---@field playing_card any
---@field children table
---@field added_to_deck boolean
---@field edition table|nil
---@overload fun(...): Card
---@field draw fun(self: Card, layer: string|nil)
---@field set_selected fun(self: Card, is_highlighted: boolean)
---@field flip fun(self: Card)
---@field hard_set_T fun(self: Card, X: number|nil, Y: number|nil, W: number|nil, H: number|nil)
---@field apply_center fun(self: Card, center: CardCenter, initial: boolean|nil, delay_sprites: boolean|nil)
---@field apply_face fun(self: Card, card: table|nil, initial: boolean|nil)
---@field update_alert fun(self: Card)
---@field set_sprites fun(self: Card, center: table|nil, front: table|nil)
---@field get_nominal fun(self: Card, mod: string|nil): number
---@field get_id fun(self: Card): number
---@field get_original_letter fun(self: Card): any
---@field set_card_area fun(self: Card, area: CardArea)
---@field remove_from_area fun(self: Card)
---@field align fun(self: Card)
---@field load fun(self: Card, cardTable: table)
---@field set_edition fun(self: Card, edition: table|nil, immediate: boolean|nil, silent: boolean|nil)


---@field set_debuff fun(self: Card, should_debuff: boolean)
---@field add_to_deck fun(self: Card, from_debuff: boolean|nil)
---@field remove_from_deck fun(self: Card, from_debuff: boolean|nil)
Card = EaseNode:derive("Card")

require "word_game.model.cards.card_ability"
require "word_game.ui.card_visuals"
require "word_game.ui.card_ui"

--class methods

--- Static scalar defaults shared by every new card. Mutable defaults
--- (tilt_var, discard_pos, children) are built per-instance in construct()
--- so instances never alias each other's tables.
local CARD_SCHEMA = {
    -- interaction
    click_timeout = 0.3,
    selected = false,
    debuff = false,
    -- visuals / animation
    facing = "front",
    sprite_facing = "front",
    zoom = true,
    ambient_tilt = 0.2,
}

--- @param X number initial x position (room units)
--- @param Y number initial y position (room units)
--- @param W number width
--- @param H number height
--- @param card table|nil base playing-card data, see `apply_face`
--- @param center table|nil center definition (companion/charm/etc.), see `apply_center`
--- @param params table|nil extra flags: `playing_card`, `viewed_back`,
---   `bypass_discovery_center`, `bypass_discovery_ui`, `bypass_lock`, etc.
function Card:construct(X, Y, W, H, card, center, params)
    local p = (type(params) == "table") and params or {}

    EaseNode.construct(self, X, Y, W, H)
    self.CT = self.VT

    for field, default in pairs(CARD_SCHEMA) do
        self[field] = default
    end

    -- Per-instance mutable state.
    self.params = p
    self.config = { card = card or {}, center = center }
    self.tilt_var = { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 }
    self.discard_pos = {
        r = 3.6 * (math.random() - 0.5),
        x = math.random(),
        y = math.random(),
    }
    self.children = {}
    self.children.shadow = EaseNode(0, 0, 0, 0)

    -- Flags forwarded from params.
    self.playing_card = p.playing_card
    self.back = p.viewed_back and "viewed_back" or "selected_back"
    self.bypass_discovery_center = p.bypass_discovery_center
    self.bypass_discovery_ui = p.bypass_discovery_ui
    self.bypass_lock = p.bypass_lock
    self.no_ui = self.config.card.no_ui

    -- Identity / ordering.
    G.sort_id = (G.sort_id or 0) + 1
    self.sort_id = G.sort_id
    self.unique_val = 1 - self.ID / 1603301
    self.edition = nil
    self.area = nil

    self.states.collide.can = true
    self.states.hover.can = true
    self.states.drag.can = true
    self.states.click.can = true

    self:apply_center(center, true)
    self:apply_face(card, true)

    self.T.scale = 0.95

    if self.children.front then self.children.front.VT.w = 0 end
    self.children.back.VT.w = 0
    self.children.center.VT.w = 0

    if self.children.front then self.children.front.parent = self; self.children.front.parallax_shift = nil end
    self.children.back.parent = self; self.children.back.parallax_shift = nil
    self.children.center.parent = self; self.children.center.parallax_shift = nil

    -- Intentionally left unset (checked purely for truthiness elsewhere).
    self.slot = nil
    self.added_to_deck = nil

    if getmetatable(self) == Card then
        table.insert(G.LIVE.CARD, self)
    end
end

--- Shows/hides the "new item discovered" alert badge on collection screens
--- (companions/perks/usables/editions/boosters only).
function Card:update_alert()
    if (self.ability.set == 'Companion' or self.ability.set == 'Perk' or self.ability.usable or self.ability.set == 'Finish' or self.ability.set == 'Bundle') then 
        if self.area and self.area.config.collection and self.config.center then
            if self.config.center.alerted and self.children.alert  then
                self.children.alert:remove()
                self.children.alert = nil
            elseif not self.config.center.alerted and not self.children.alert and self.config.center.discovered then
                self.children.alert = LayoutView{
                    definition = build_card_alert(), 
                    config = {align=(self.ability.set == 'Perk' and (self.config.center.order%2)==1) and "tli" or "tri",
                            offset = {x = (self.ability.set == 'Perk' and (self.config.center.order%2)==1) and 0.1 or -0.1, y = 0.1},
                            parent = self}
                }
            end
        end
    end
end

-- ============ Sprites & Base Playing-Card Data ============

-- Reverse lookup from face definition to its P_CARDS key, memoised so
-- apply_face stays O(1) after the first call.
local face_keys = setmetatable({}, {__mode = "k"})
local function face_key(definition)
	if type(definition) ~= "table" then return nil end
	if not next(face_keys) then
		for key, def in pairs(G.P_CARDS) do face_keys[def] = key end
	end
	return face_keys[definition]
end

--- Sets/refreshes this card's letter face (`self.base`: name/letter/color).
--- @param card table|nil raw card data (see `G.P_CARDS`); empty table = blank/no card
--- @param initial boolean|nil true during `Card:init` (skips some update-only work)
function Card:apply_face(card, initial)
    card = card or {}

    self.config.card = card
    self.config.card_key = face_key(card)

    if next(card) then
        self:set_sprites(nil, card)
    end

    local card_color = self.config.card.color
    local card_colour = (card_color == "red" and G.C.RED)
        or (card_color == "black" and G.C.BLACK)
        or G.C.BLACK
    local letter = self.config.card.letter
    local idx = 0
    if type(letter) == "string" and #letter == 1 then
        idx = string.byte(letter) - string.byte("A") + 1
    end
    self.base = {
        name = self.config.card.name,
        letter = letter,
        color = card_color,
        value = letter or self.config.card.value,
        letter_index = idx,
        id = idx,
        color_tiebreak = card_color == "red" and 0.01 or (card_color == "black" and 0.02 or 0),
        face_tiebreak = 0,
        colour = card_colour,
        times_played = 0
    }

    if initial then self.base.original_value = self.base.value end 

end

--- Sort key: letter index, then colour, then a per-instance tiebreaker so
--- identical letters keep a stable relative order.
function Card:get_nominal(mod)
	local weight = (mod == 'color' or mod == 'suit') and 1000 or 1
	return self.base.letter_index
		+ (self.base.color_tiebreak or 0) * weight
		+ (self.base.color_tiebreak_original or 0) * 0.0001 * weight
		+ (self.base.face_tiebreak or 0)
		+ 0.000001 * self.unique_val
end

function Card:get_id()
    return self.base.id
end

function Card:get_original_letter()
    return self.base.original_value
end


function Card:set_card_area(area)
    self.area = area
    self.parent = area
    self.parallax_shift = area.parallax_shift
end


function Card:remove_from_area()
    self.area = nil
    self.parent = nil
    self.parallax_shift = {x = 0, y = 0}
end


function Card:align()  
    if self.children.floating_sprite then 
        self.children.floating_sprite.T.y = self.T.y
        self.children.floating_sprite.T.x = self.T.x
        self.children.floating_sprite.T.r = self.T.r
    end

    if self.children.focused_ui then self.children.focused_ui:set_alignment() end
end


-- Fields round-tripped verbatim between save and load. Anything not listed
-- here is rebuilt by construct()/apply_* on load instead of restored.
local SAVED_FIELDS = {
    "no_ui", "facing", "sprite_facing", "selected", "debuff",
    "slot", "added_to_deck", "label", "playing_card", "base", "sort_id",
    "bypass_discovery_center", "bypass_discovery_ui", "bypass_lock",
    "ability", "pinned", "edition", "seal",
}

--- Current save-format version. Bump whenever the layout produced by
--- `Card:save()` changes; loaders migrate older payloads via `migrate_*`.
Card.SAVE_VERSION = 2

--- Converts a v1 payload (flat SAVED_FIELDS plus a nested `save_fields` ref
--- table) into the current versioned format.
local function migrate_v1_save(old)
    local state = {}
    for _, field in ipairs(SAVED_FIELDS) do
        state[field] = old[field]
    end
    return {
        version = 2,
        refs = {
            center = old.save_fields and old.save_fields.center,
            card = old.save_fields and old.save_fields.card,
        },
        params = old.params,
        state = state,
    }
end

function Card:save()
    local state = {}
    for _, field in ipairs(SAVED_FIELDS) do
        state[field] = self[field]
    end
    return {
        version = Card.SAVE_VERSION,
        refs = {
            center = self.config.center_key,
            card = self.config.card_key,
        },
        params = self.params,
        state = state,
    }
end


function Card:load(saved)
    if type(saved) ~= "table" or not saved.version then
        saved = migrate_v1_save(saved or {})
    end

    self.config = {
        center_key = saved.refs.center,
        center = G.P_CENTERS[saved.refs.center],
        card_key = saved.refs.card,
        card = G.P_CARDS[saved.refs.card],
    }
    self.params = saved.params

    -- Bundle-wrapped perk offers display slightly oversized; everything else
    -- is a standard-size card.
    local H, W = G.CARD_H, G.CARD_W
    if self.config.center.set == 'Bundle' then
        self.T.h, self.T.w = H * 1.27, W * 1.27
    else
        self.T.h, self.T.w = H, W
    end
    self.VT.h = self.T.h
    self.VT.w = self.T.w

    for _, field in ipairs(SAVED_FIELDS) do
        self[field] = saved.state[field]
    end

    teardown_tree(self.children)
    self.children = { shadow = EaseNode(0, 0, 0, 0) }

    self:set_sprites(self.config.center, self.config.card)
end


function Card:remove()
    self.removed = true

    if self.area then self.area:remove_card(self) end

    self:remove_from_deck()

    if G.playing_cards then
        for k, v in ipairs(G.playing_cards) do
            if v == self then
                table.remove(G.playing_cards, k)
                break
            end
        end
        for k, v in ipairs(G.playing_cards) do
            v.playing_card = k
        end
    end

    teardown_tree(self.children)

    for k, v in pairs(G.LIVE.CARD) do
        if v == self then
            table.remove(G.LIVE.CARD, k)
            break
        end
    end
    EaseNode.remove(self)
end

