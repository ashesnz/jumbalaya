--[[ tests/unit/test_hand_shuffle.lua - Hand shuffle/remove button state ]]

local T = require("tests.framework")

T.describe("Hand shuffle/remove button", function()
	T.it("detects placement cards from the placement area and jumble slots", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
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
		_G.get_hand_area_width = function(size)
			return (G.CARD_W or 2) * (size or 7) * (G.HAND_CARD_SPACING or 0.78)
		end
		G.STATE = G.STATES.TABLE_BOARD
		G.STATES = G.STATES or { TABLE_BOARD = 1 }
		G.ROOM_ATTACH = G.ROOM_ATTACH or { T = { x = 0, y = 0, w = 20, h = 11.5 } }
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.CARD_W = 2
		G.CARD_H = 2.8
		G.TABLE_HAND_SIZE = 7
		G.ROOM = { T = { x = 0, y = 0, w = 20, h = 11.5 } }
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
end)
