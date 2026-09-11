--[[ tests/unit/test_bonus_gutter_input.lua - Bonus gutter touch drag and placement ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local game_access = require("word_game.model.game_access")

local function layout_globals()
	game_access.mutate(function(g)
		g.word_round = {
			mode = "jumble",
			jumble = { boss_word_active = true, puzzle = { min = 3, max = 7 } },
		}
	end)
	G.TILE_W = 20
	G.TILE_H = 11.5
	G.CARD_W = 2
	G.CARD_H = 2.8
	G.ROOM = {
		T = { x = 1, y = 0, w = 20, h = 11.5 },
		states = { hover = { can = true }, click = { can = false }, drag = { can = false } },
		collides_with_point = function() return true end,
	}
	G.dealt_letters = { T = { x = 3.2, y = 8.0, w = 10.5, h = 2.8 }, cards = {} }
	G.pattern_row = {
		area = {
			T = { x = 0.6, y = 2.0, w = 18.0, h = 2.8 },
			cards = {},
			hard_set_cards = function() end,
		},
		relayout = function() end,
	}
end

local function mock_draggable_card(x, y, w, h)
	w = w or 2
	h = h or 2.8
	return {
		T = { x = x, y = y, w = w, h = h, r = 0 },
		VT = { x = x, y = y, w = w, h = h, r = 0 },
		states = {
			drag = { can = true, is = false },
			collide = { can = true, is = false },
			hover = { can = true, is = false },
			click = { can = false },
		},
		collides_with_point = function(self, pt)
			return pt.x >= self.T.x and pt.x <= self.T.x + self.T.w
				and pt.y >= self.T.y and pt.y <= self.T.y + self.T.h
		end,
		can_drag = function(self) return self end,
		set_offset = function() end,
		drag = function() end,
		stop_drag = function() end,
	}
end

local function mock_hand()
	return {
		T = { x = 3.2, y = 8.0, w = 10.5, h = 2.8 },
		cards = {},
		emplace = function(self, card)
			self.cards[#self.cards + 1] = card
			card.area = self
		end,
		remove_card = function(self, card)
			for i, held in ipairs(self.cards) do
				if held == card then
					table.remove(self.cards, i)
					if card.remove_from_area then card:remove_from_area() end
					return card
				end
			end
		end,
		relayout = function() end,
		snap_VT = function() end,
		hard_set_cards = function() end,
	}
end

T.describe("bonus gutter input", function()
	local bonus_stack = require("word_game.ui.perks.bonus_stack")
	local draw = require("word_game.ui.perks.bonus_stack.draw")
	local jumble = require("word_game.model.jumble")

	T.it("does not draw a filled gutter backdrop behind bonus cards", function()
		T.assert_nil(draw.draw_shadow, "gutter backdrop draw path should be removed")
	end)

	T.it("starts a touch drag when pressing a gutter bonus card", function()
		mock_env.ensure_engine_globals()
		layout_globals()
		G.TILESCALE = 1
		G.TILESIZE = 71
		G.DRAW_HASH_BUFF = 2
		G.TIMERS = G.TIMERS or { TOTAL = 0 }
		G.SETTINGS = G.SETTINGS or { paused = false }
		G.MIN_CLICK_DIST = 0.2

		local card = mock_draggable_card(0.2, 4.5)
		card.bonus_card = true
		G.HIT_ORDER = { G.ROOM, card }

		local InputRouter = require("jumbalaya-engine.interaction.router")
		local input = InputRouter()
		G.INPUT = input
		input:set_HID_flags("touch")

		local cx = (card.T.x + card.T.w * 0.5) * G.TILESIZE
		local cy = (card.T.y + card.T.h * 0.5) * G.TILESIZE
		input.deferred_press = { x = cx, y = cy }
		input:update_interact(0)

		T.assert_equal(input.dragging.target, card, "touch press should grab the gutter bonus card")
		T.assert_true(card.states.drag.is, "bonus card drag state should be active")
		T.assert_equal(type(input.press_state.T), "table")
		T.assert_not_nil(input.press_state.T.x)
		T.assert_not_nil(input.press_state.T.y)

		input.release_state.handled = true
		input.press_state.handled = true
		input:L_cursor_release(cx + 4, cy + 4)
		T.assert_equal(type(input.release_state.T), "table")
		T.assert_not_nil(input.release_state.T.x)
	end)

	T.it("places a gutter bonus card into a placement blank", function()
		bonus_stack.clear()
		layout_globals()
		G.dealt_letters = mock_hand()
		local snap = require("word_game.board.placement.snap")
		local card = {
			ability = { letter = "B", bonus = 10 },
			T = { x = 0.2, y = 4.5, w = 2, h = 2.8, r = 0 },
			VT = { x = 0.2, y = 4.5, w = 2, h = 2.8, r = 0 },
			states = { drag = { can = true, is = false }, collide = { can = true } },
			hard_set_T = function(self, nx, ny, nw, nh)
				self.T.x, self.T.y = nx or self.T.x, ny or self.T.y
				self.T.w, self.T.h = nw or self.T.w, nh or self.T.h
				self.VT.x, self.VT.y = self.T.x, self.T.y
			end,
			remove_from_area = function(self) self.area = nil end,
			set_card_area = function(self, area) self.area = area end,
		}
		bonus_stack.promote_to_bonus({ card })
		local slots = { { kind = "blank", card = nil } }
		game_access.mutate(function(g)
			g.word_round = {
				mode = "jumble",
				jumble = {
					slots = slots,
					puzzle = { min = 3, max = 7 },
				},
			}
		end)
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function()
				local wr = game_access.word_round()
				return wr and wr.jumble
			end,
			slot_for_card = jumble.slot_for_card,
			remove_card_from_blanks = jumble.remove_card_from_blanks,
			assign_card_to_blank = jumble.assign_card_to_blank,
			blank_slot_index_for_x = jumble.blank_slot_index_for_x,
			first_empty_blank = jumble.first_empty_blank,
			sync_placement_cards = jumble.sync_placement_cards,
			build_word = jumble.build_word,
		}

		local blank_x = G.pattern_row.area.T.x + G.CARD_W * 0.5
		card.T.x = blank_x - card.T.w * 0.5
		card.T.y = G.pattern_row.area.T.y

		snap.try_snap({
			area = G.pattern_row.area,
			ctx = {
				card_w = function() return G.CARD_W end,
				card_h = function() return G.CARD_H end,
			},
		}, card)

		T.assert_equal(slots[1].card, card, "gutter bonus card should land in a placement blank")
		T.assert_equal(card.area, G.pattern_row.area)
		T.assert_true(card.T.x >= G.pattern_row.area.T.x,
			"placed bonus card should sit in the puzzle row, not the gutter")
		bonus_stack.clear()
	end)
end)
