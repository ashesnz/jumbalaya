--[[ word_game/ui/cardarea/lifecycle.lua - Card pile membership, shuffle, persistence ]]

local GameRT = require("word_game.ui.util.game_runtime")
local Tables = require("jumbalaya-engine.util.tables")
local Random = require("jumbalaya-engine.util.random")
local facade = require("word_game.ui.facade")

local Deck = facade.deck()
local Jumble = facade.jumble()

local M = {}

local function runtime()
	return GameRT.game()
end

local function table_board()
	return runtime().STATE == runtime().STATES.TABLE_BOARD
end

function M.emplace(self, card, location, stay_flipped)
	if table_board() and card and card.bonus_card and (self == runtime().dealt_letters or self == runtime().draw_pile) then
		local origin_slot, origin_insert
		if Jumble.slot_for_card then
			origin_slot, origin_insert = Jumble.slot_for_card(card)
		end
		facade.board_snap().restore_bonus_card(runtime().pattern_row, card, origin_slot, origin_insert)
		return
	end
	if location == 'front' or self.config.type == 'deck' then
		table.insert(self.cards, 1, card)
	else
		self.cards[#self.cards+1] = card
	end
	if table_board() then
		if self == runtime().dealt_letters and Deck.reveal_in_hand then
			Deck.reveal_in_hand(card)
		end
	elseif card.facing == 'back' and self.config.type ~= 'discard' and self.config.type ~= 'deck' and not stay_flipped then
		card:flip()
	elseif self == runtime().dealt_letters and stay_flipped then
		card.ability.wheel_flipped = true
	end

	if self == runtime().draw_pile and #self.cards > self.config.card_limit then
		self.config.card_limit = #self.cards
	end

	card:set_card_area(self)
	self:set_ranks()
	self:relayout()
end

function M.remove_card(self, card, discarded_only, type_handler)
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

	if card == nil then
		local handler = type_handler(self)
		if handler and handler.remove_target then
			card = handler.remove_target(self, candidates, nil)
		else
			card = candidates[1]
		end
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

function M.shuffle(self, _seed)
	Random.shuffle_seeded(self.cards, Random.advance_seed(_seed or 'shuffle'))
	self:set_ranks()
end

function M.sort(self, method)
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

function M.draw_card_from(self, area, stay_flipped, discarded_only)
	if area:is_kind(CardPile) then
		if #self.cards < self.config.card_limit or self == runtime().draw_pile or self == runtime().dealt_letters then
			local card = area:remove_card(nil, discarded_only)
			if card then
				if area == runtime().recycle_stash then
					card.T.r = 0
				end
				self:emplace(card)
				return true
			end
		end
	end
end

function M.save(self)
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

function M.load(self, cardAreaTable)
	Tables.teardown_tree(self.cards or {})
	self.cards = {}
	Tables.teardown_tree(self.children or {})
	self.children = {}
	self.selected = {}

	self.config = cardAreaTable.config

	for i = 1, #cardAreaTable.cards do
		local card = Card(0, 0, runtime().CARD_W, runtime().CARD_H, runtime().LETTERS.faces.empty, runtime().LETTERS.centers.letter_base, nil)
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

function M.remove(self, type_handler)
	local handler = type_handler(self)
	if handler and handler.on_remove then
		handler.on_remove(self)
	end
	Tables.teardown_tree(self.cards or {})
	self.cards = nil
	Tables.teardown_tree(self.children or {})
	self.children = nil
	for k, v in pairs(runtime().LIVE.CARDPILE) do
		if v == self then
			table.remove(runtime().LIVE.CARDPILE, k)
		end
	end
	EaseNode.remove(self)
end

return M
