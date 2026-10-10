--[[
	word_game/model/cards/letter_tile.lua - LetterTile: presentation view over store piles + letter id

	A jumble tile holds letter, modifiers, facing, pile id, and sprites.
	Ability math lives in jumbalaya_core.cards.letter_card.

	Mixins: ui/cards/visuals, ui, alerts, align at boot.

	Core: jumbalaya_core.cards.letter_card
	Store: letter_card_id / pile_id (store.piles is authoritative)
	Presentation: none
]]

local Tables = require("jumbalaya-engine.util.tables")
local SceneRoots = require("jumbalaya-engine.scene.roots")
local CoreLetter = require("jumbalaya_core.cards.letter_card")

---@class (partial) LetterTile : EaseNode
---@field ability CardAbility
---@field base table
---@field config table
---@field area CardPile|nil
---@field selected boolean
---@field letter_card_id number|nil
---@field pile_id string|nil
---@field children table
---@field added_to_deck boolean
---@overload fun(...): LetterTile
---@field draw fun(self: LetterTile, layer: string|nil)
---@field set_selected fun(self: LetterTile, is_highlighted: boolean)
---@field flip fun(self: LetterTile)
---@field hard_set_T fun(self: LetterTile, X: number|nil, Y: number|nil, W: number|nil, H: number|nil)
---@field apply_face fun(self: LetterTile, card: table|nil, initial: boolean|nil)
---@field update_alert fun(self: LetterTile)
---@field set_sprites fun(self: LetterTile, front: table|nil)
---@field get_nominal fun(self: LetterTile, mod: string|nil): number
---@field get_id fun(self: LetterTile): number
---@field get_original_letter fun(self: LetterTile): any
---@field set_card_area fun(self: LetterTile, area: CardPile)
---@field remove_from_area fun(self: LetterTile)
---@field align fun(self: LetterTile)
---@field load fun(self: LetterTile, cardTable: table)
---@field set_debuff fun(self: LetterTile, should_debuff: boolean)
---@field add_to_deck fun(self: LetterTile, from_debuff: boolean|nil)
---@field remove_from_deck fun(self: LetterTile, from_debuff: boolean|nil)
local live_game = require("word_game.model.live_game")
local shell = require("word_game.model.shell_access")
local CardRegistry = require("word_game.model.cards.registry")
local Deck = require("word_game.model.cards.deck")
local AnimNode = require("jumbalaya-engine.scene.animated.init")

local LetterTile = AnimNode:derive("LetterTile")

local TILE_SCHEMA = {
	click_timeout = 0.3,
	selected = false,
	debuff = false,
	facing = "front",
	sprite_facing = "front",
	zoom = true,
	ambient_tilt = 0.2,
}

--- @param X number
--- @param Y number
--- @param W number
--- @param H number
--- @param face table|nil letter face from LETTERS.faces
--- @param params table|nil `letter_card_id`, `pile_id`, `viewed_back`
function LetterTile:construct(X, Y, W, H, face, params)
	local p = (type(params) == "table") and params or {}

	EaseNode.construct(self, X, Y, W, H)
	self.CT = self.VT

	for field, default in pairs(TILE_SCHEMA) do
		self[field] = default
	end

	self.params = p
	self.config = { card = face or {} }
	self.tilt_var = { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 }
	self.discard_pos = {
		r = 3.6 * (math.random() - 0.5),
		x = math.random(),
		y = math.random(),
	}
	self.children = { shadow = EaseNode(0, 0, 0, 0) }

	self.letter_card_id = p.letter_card_id
	self.pile_id = p.pile_id or "draw"
	self.back = p.viewed_back and "viewed_back" or "selected_back"
	self.no_ui = self.config.card.no_ui

	self.sort_id = shell.next_sort_id()
	self.area = nil

	self.states.collide.can = true
	self.states.hover.can = true
	self.states.drag.can = true
	self.states.click.can = true

	self:apply_face(face, true)

	self.T.scale = 0.95

	if self.children.front then self.children.front.VT.w = 0 end
	if self.children.back then self.children.back.VT.w = 0 end
	if self.children.center then self.children.center.VT.w = 0 end

	if self.children.front then self.children.front:set_scene_parent(self); self.children.front.parallax_shift = nil end
	if self.children.back then self.children.back:set_scene_parent(self); self.children.back.parallax_shift = nil end
	if self.children.center then self.children.center:set_scene_parent(self); self.children.center.parallax_shift = nil end

	self.slot = nil
	self.added_to_deck = nil

	if getmetatable(self) == LetterTile then
		table.insert(live_game().LIVE.CARD, self)
	end
end

local face_keys = setmetatable({}, { __mode = "k" })
local function face_key(definition)
	if type(definition) ~= "table" then return nil end
	local cached = face_keys[definition]
	if cached then return cached end
	for key, def in pairs(CardRegistry.faces() or {}) do
		face_keys[def] = key
	end
	return face_keys[definition]
end

function LetterTile:apply_face(card, initial)
	card = card or {}

	self.config.card = card
	self.config.card_key = face_key(card)

	if next(card) then
		self:set_sprites(card)
	end

	local Palette = require "word_game.config.visuals.letter_card_palette"
	local card_color = self.config.card.color or Palette.DEFAULT_FACE_COLOR
	local card_colour = Palette.ui_color(card_color) or Palette.default_fill()
	local letter = self.config.card.letter
	local idx = CoreLetter.letter_index(letter)
	self.base = {
		name = self.config.card.name,
		letter = letter,
		color = card_color,
		value = letter or self.config.card.value,
		letter_index = idx,
		id = idx,
		color_tiebreak = CoreLetter.color_tiebreak(card_color),
		face_tiebreak = 0,
		colour = card_colour,
		times_played = 0,
	}

	self.ability = CoreLetter.ability_from_face(self.config.card, self.ability)

	if initial then self.base.original_value = self.base.value end
end

function LetterTile:get_nominal(mod)
	local weight = (mod == "color" or mod == "suit") and 1000 or 1
	return self.base.letter_index
		+ (self.base.color_tiebreak or 0) * weight
		+ (self.base.color_tiebreak_original or 0) * 0.0001 * weight
		+ (self.base.face_tiebreak or 0)
		+ 1e-9 * (self.sort_id or self.ID or 0)
end

function LetterTile:get_id()
	return self.base.id
end

function LetterTile:get_original_letter()
	return self.base.original_value
end

function LetterTile:set_card_area(area)
	self.area = area
	self:set_scene_parent(area)
	self.parallax_shift = area.parallax_shift
	if area and area.config and area.config.type then
		local t = area.config.type
		if t == "deck" then t = "draw" end
		if t == "placement" then t = "pattern" end
		self.pile_id = t
	end
end

function LetterTile:remove_from_area()
	self.area = nil
	self:set_scene_parent(nil)
	SceneRoots.unregister(self)
	self.parallax_shift = { x = 0, y = 0 }
end

function LetterTile:add_to_deck()
	if self.added_to_deck then return end
	self.added_to_deck = true
end

function LetterTile:remove_from_deck()
	self.added_to_deck = false
end

local SAVED_FIELDS = {
	"no_ui", "facing", "sprite_facing", "selected", "debuff",
	"slot", "added_to_deck", "label", "letter_card_id", "pile_id", "base", "sort_id",
	"ability", "pinned",
}

LetterTile.SAVE_VERSION = 5

local function migrate_v1_save(old)
	local state = {}
	for _, field in ipairs(SAVED_FIELDS) do
		state[field] = old[field]
	end
	return {
		version = LetterTile.SAVE_VERSION,
		refs = { card = old.save_fields and old.save_fields.card },
		params = old.params,
		state = state,
	}
end

local function migrate_v2_save(saved)
	local refs = saved.refs or {}
	return {
		version = LetterTile.SAVE_VERSION,
		refs = { card = refs.card },
		params = saved.params,
		state = saved.state or {},
	}
end

function LetterTile:save()
	local state = {}
	for _, field in ipairs(SAVED_FIELDS) do
		state[field] = self[field]
	end
	return {
		version = LetterTile.SAVE_VERSION,
		refs = { card = self.config.card_key },
		params = self.params,
		state = state,
	}
end

function LetterTile:load(saved)
	if type(saved) ~= "table" or not saved.version then
		saved = migrate_v1_save(saved or {})
	elseif saved.version == 2 or saved.version == 3 or saved.version == 4 then
		saved = migrate_v2_save(saved)
	end

	self.config = {
		card_key = saved.refs and saved.refs.card,
		card = CardRegistry.faces() and CardRegistry.faces()[saved.refs and saved.refs.card],
	}
	self.params = saved.params or {}

	local H, W = live_game().CARD_H, live_game().CARD_W
	self.T.h, self.T.w = H, W
	self.VT.h = self.T.h
	self.VT.w = self.T.w

	for _, field in ipairs(SAVED_FIELDS) do
		self[field] = saved.state[field]
	end

	Tables.teardown_tree(self.children)
	self.children = { shadow = EaseNode(0, 0, 0, 0) }

	self:set_sprites(self.config.card)

	if self.ability and self.ability.modified then
		Deck.restore_letter_face(self)
	end
end

function LetterTile:remove()
	self.removed = true

	if self.area then self.area:remove_card(self) end

	self:remove_from_deck()

	if live_game().letter_inventory then
		for k, v in ipairs(live_game().letter_inventory) do
			if v == self then
				table.remove(live_game().letter_inventory, k)
				break
			end
		end
		for k, v in ipairs(live_game().letter_inventory) do
			v.letter_card_id = k
		end
	end

	Tables.teardown_tree(self.children)

	for k, v in pairs(live_game().LIVE.CARD) do
		if v == self then
			table.remove(live_game().LIVE.CARD, k)
			break
		end
	end
	EaseNode.remove(self)
end

return LetterTile
