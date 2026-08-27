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
	G.GAME.alpha = G.GAME.alpha or {}
	WORD_GAME = WORD_GAME or {}
	WORD_GAME.Jumble = {
		is_active = function() return false end,
		state = function() return nil end,
	}
	stub_icon_atlas("play_icon")
	stub_icon_atlas("shuffle_icon")
	stub_icon_atlas("remove_placement_icon")
end

T.describe("Hand shuffle/remove button", function()
	T.it("detects placement cards from the placement area and jumble slots", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.placement_table = {
			area = { cards = {} },
		}
		T.assert_equal(false, HandShuffle.placement_has_cards())

		G.placement_table.area.cards = { { ability = { letter = "A" } } }
		T.assert_equal(true, HandShuffle.placement_has_cards())

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
		T.assert_equal(true, HandShuffle.placement_has_cards())
	end)

	T.it("anchors shuffle and play buttons from felt layout, not live hand drift", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = { T = { x = 99, y = 99, w = 1, h = 1 }, cards = {} }
		HandShuffle.destroy()
		HandShuffle.ensure()
		local shuffle_btn = HandShuffle.shuffle_button_uie()
		local play_btn = HandShuffle.play_button_uie()
		T.assert_not_nil(shuffle_btn)
		T.assert_not_nil(play_btn)
		local before_shuffle = shuffle_btn.T.x
		local before_play = play_btn.T.x
		G.hand.T.x = 3.5
		G.hand.T.w = 12
		HandShuffle.sync_position()
		T.assert_almost_equal(before_shuffle, shuffle_btn.T.x, 0.001)
		T.assert_almost_equal(before_play, play_btn.T.x, 0.001)
		HandShuffle.destroy()
	end)

	T.it("keeps shuffle button position when hand card count changes", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		HandShuffle.destroy()
		HandShuffle.ensure()
		local shuffle_btn = HandShuffle.shuffle_button_uie()
		T.assert_not_nil(shuffle_btn)
		local full_hand_x = shuffle_btn.T.x
		local full_hand_y = shuffle_btn.T.y
		G.hand.cards = { {}, {} }
		HandShuffle.stabilize()
		T.assert_almost_equal(full_hand_x, shuffle_btn.T.x, 0.001)
		T.assert_almost_equal(full_hand_y, shuffle_btn.T.y, 0.001)
		HandShuffle.destroy()
	end)

	T.it("keeps shuffle button and icon position when toggling shuffle and remove modes", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.placement_table.area.cards = {}
		HandShuffle.destroy()
		HandShuffle.ensure()
		HandShuffle.sync_visibility()

		local shuffle_btn = HandShuffle.shuffle_button_uie()
		T.assert_not_nil(shuffle_btn)
		local icon = G.hand_shuffle_bar:find_node_by_id("hand_shuffle_icon")
		T.assert_not_nil(icon)

		local btn_x, btn_y = shuffle_btn.T.x, shuffle_btn.T.y
		local icon_x, icon_y = icon.T.x, icon.T.y
		local sprite = icon.config.object
		T.assert_not_nil(sprite)
		T.assert_equal("shuffle_icon", sprite.atlas.name)

		G.placement_table.area.cards = { { ability = { letter = "A" } } }
		HandShuffle.sync_visibility()
		HandShuffle.stabilize()

		T.assert_almost_equal(btn_x, shuffle_btn.T.x, 0.001)
		T.assert_almost_equal(btn_y, shuffle_btn.T.y, 0.001)
		T.assert_almost_equal(icon_x, icon.T.x, 0.001)
		T.assert_almost_equal(icon_y, icon.T.y, 0.001)
		T.assert_equal("remove_placement_icon", sprite.atlas.name)

		G.placement_table.area.cards = {}
		HandShuffle.sync_visibility()
		HandShuffle.stabilize()

		T.assert_almost_equal(btn_x, shuffle_btn.T.x, 0.001)
		T.assert_almost_equal(btn_y, shuffle_btn.T.y, 0.001)
		T.assert_almost_equal(icon_x, icon.T.x, 0.001)
		T.assert_almost_equal(icon_y, icon.T.y, 0.001)
		T.assert_equal("shuffle_icon", sprite.atlas.name)
		HandShuffle.destroy()
	end)

	T.it("anchors shuffle button to max hand width, not the current card group width", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {} } }
		HandShuffle.destroy()
		HandShuffle.ensure()
		local two_card_x = HandShuffle.shuffle_button_uie().T.x

		G.hand.cards = { {}, {}, {}, {}, {}, {}, {} }
		HandShuffle.invalidate_layout()
		HandShuffle.sync_position()
		local seven_card_x = HandShuffle.shuffle_button_uie().T.x

		T.assert_almost_equal(two_card_x, seven_card_x, 0.001)
		HandShuffle.destroy()
	end)
end)
