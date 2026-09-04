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

	T.it("recreates play and shuffle buttons after an early sync with no hand", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = nil
		HandShuffle.destroy()
		T.assert_false(HandShuffle.sync(), "Sync without a hand should not leave buttons")

		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		T.assert_true(HandShuffle.sync(), "Sync after the hand exists should create buttons")
		T.assert_true(HandShuffle.buttons_present(), "Play and shuffle buttons should exist")
		local shuffle_btn = HandShuffle.shuffle_button_uie()
		local play_btn = HandShuffle.play_button_uie()
		T.assert_not_nil(shuffle_btn)
		T.assert_not_nil(play_btn)
		T.assert_true(shuffle_btn.states.visible, "Shuffle button should be visible in gameplay")
		T.assert_true(play_btn.states.visible, "Play button should be visible in gameplay")
		T.assert_equal(shuffle_btn.config.button, "shuffle_hand")
		T.assert_equal(play_btn.config.button, "play_placement_word")
		HandShuffle.destroy()
	end)

	T.it("keeps play and shuffle buttons present through table board sync cycles", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		local table_board = require("word_game.ui.table_board")
		setup_hand_shuffle_env()
		WORD_GAME.HandShuffle = HandShuffle
		G.hand = nil
		HandShuffle.destroy()

		HandShuffle.sync()
		T.assert_false(HandShuffle.buttons_present(), "Buttons should not exist before the hand is dealt")

		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		table_board.update({ STATE = G.STATE }, 0.016)
		T.assert_true(HandShuffle.buttons_present(), "Table board update should restore action buttons")
		T.assert_true(HandShuffle.play_button_uie().states.visible)
		T.assert_true(HandShuffle.shuffle_button_uie().states.visible)

		table_board.update({ STATE = G.STATE }, 0.016)
		T.assert_true(HandShuffle.buttons_present(), "Buttons should stay present on subsequent updates")
		HandShuffle.destroy()
	end)

	T.it("keeps play and shuffle buttons present in jumble gameplay mode", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.GAME.word_round = { mode = "jumble", jumble = { slots = {} } }
		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function() return G.GAME.word_round.jumble end,
		}
		HandShuffle.destroy()
		T.assert_true(HandShuffle.sync(), "Jumble mode should still create action buttons")
		local play_btn = HandShuffle.play_button_uie()
		local shuffle_btn = HandShuffle.shuffle_button_uie()
		T.assert_equal(play_btn.config.button, "play_placement_word")
		T.assert_equal(shuffle_btn.config.button, "shuffle_hand")
		T.assert_true(play_btn.states.visible)
		T.assert_true(shuffle_btn.states.visible)
		HandShuffle.destroy()
	end)

	T.it("restores buttons via sidebar sync when vault sync runs before the hand is dealt", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		local hud_definition = require("word_game.ui.sidebar.hud_definition")
		setup_hand_shuffle_env()
		WORD_GAME.HandShuffle = HandShuffle
		G.hand = nil
		HandShuffle.destroy()
		hud_definition.sync_action_buttons()
		T.assert_false(HandShuffle.buttons_present())

		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		hud_definition.sync_action_buttons()
		T.assert_true(HandShuffle.buttons_present(), "Sidebar sync should create buttons once the hand exists")
		HandShuffle.destroy()
	end)

	T.it("keeps the play button clickable once the classic target is reached", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		local tt = require("word_game.ui.timeline_timer")
		setup_hand_shuffle_env()
		G.GAME.run_mode = "classic"
		G.GAME.word_round = {
			mode = "jumble",
			target = 25,
			jumble = {
				total_score = 32,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				slots = {},
			},
		}
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function() return G.GAME.word_round.jumble end,
		}
		tt.reset_progress(25)
		tt.sync_progress()
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		HandShuffle.destroy()
		T.assert_true(HandShuffle.sync())
		local play_btn = HandShuffle.play_button_uie()
		T.assert_equal(play_btn.config.button, "play_placement_word")
		T.assert_true(play_btn.states.collide.can)
		HandShuffle.destroy()
	end)

	T.it("removes play and shuffle buttons outside table board gameplay", function()
		local HandShuffle = require("word_game.ui.hand_shuffle")
		setup_hand_shuffle_env()
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = { {}, {}, {}, {}, {}, {}, {} } }
		HandShuffle.sync()
		T.assert_true(HandShuffle.buttons_present())

		G.STATE = G.STATES.MENU or 99
		HandShuffle.sync()
		T.assert_false(HandShuffle.buttons_present(), "Buttons should be removed outside gameplay")
		HandShuffle.destroy()
	end)
end)
