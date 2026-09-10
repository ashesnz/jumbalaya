--[[ tests/unit/test_hand_shuffle.lua - Hand shuffle/remove button state ]]

local T = require("tests.framework")

local function stub_icon_atlas(name)
	G.TEXTURE_ATLASES[name] = {
		px = 112,
		py = 112,
		name = name,
		image = { getDimensions = function() return 112, 112 end },
	}
end

local function setup_hand_shuffle_env()
	_G.get_hand_area_width = function(size)
		local card_w = G.CARD_W or 2
		local spacing = G.HAND_CARD_SPACING or 0.78
		return card_w + math.max((size or 7) - 1, 0) * card_w * spacing
	end
	G.STATE = G.STATES.TABLE_BOARD
	G.STATES = G.STATES or { TABLE_BOARD = 1 }
	G.ROOM_ATTACH = G.ROOM_ATTACH or { T = { x = 0, y = 0, w = 20, h = 11.5 } }
	G.TILE_W = 20
	G.TILE_H = 11.5
	G.CARD_W = 2
	G.CARD_H = 2.8
	G.HAND_CARD_SPACING = 0.78
	G.TABLE_HAND_SIZE = 7
	G.ROOM = { T = { x = 0, y = 0, w = 20, h = 11.5 } }
	G.placement_table = G.placement_table or { area = { cards = {} } }
	G.GAME = G.GAME or {}
	G.GAME.run_state = G.GAME.run_state or {}
	G.ARGS = G.ARGS or {}
	G.ARGS.pending_layout = false
	WORD_GAME = WORD_GAME or {}
	WORD_GAME.Jumble = {
		is_active = function() return false end,
		state = function() return nil end,
	}
	stub_icon_atlas("play_icon")
	stub_icon_atlas("shuffle_icon")
	stub_icon_atlas("remove_placement_icon")
end

T.describe("Table controls", function()
	T.it("detects placement cards from the placement area and jumble slots", function()
		local TableControls = require("word_game.ui.table.controls")
		setup_hand_shuffle_env()
		G.placement_table = {
			area = { cards = {} },
		}
		T.assert_equal(false, TableControls.placement_has_cards())

		G.placement_table.area.cards = { { ability = { letter = "A" } } }
		T.assert_equal(true, TableControls.placement_has_cards())

		G.placement_table.area.cards = {}
		G.GAME = {
			word_round = {
				mode = "jumble",
				jumble = {
					slots = {
						{ kind = "blank", card = nil },
						{ kind = "blank", card = { ability = { letter = "T" } } },
					},
				},
			},
		}
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = {
			is_active = function()
				return G.GAME.word_round.mode == "jumble"
			end,
			state = function()
				return G.GAME.word_round.jumble
			end,
		}
		T.assert_equal(true, TableControls.placement_has_cards())
	end)
end)
