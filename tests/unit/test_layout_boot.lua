--[[ tests/unit/test_layout_boot.lua - placement row Y stable across boot and first jumble play ]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

local function placement_y()
	local area = G.placement_table and G.placement_table.area
	return area and area.T and area.T.y or nil
end

local function hand_y()
	return G.hand and G.hand.T and G.hand.T.y or nil
end

local function felt_y()
	local Layout = require("word_game.ui.layout")
	return Layout.felt_rect().y
end

local function assert_hand_bottom_margin()
	local margin = G.TILE_H - (G.hand.T.y + G.hand.T.h)
	T.assert_almost_equal(margin, 0.25, 0.001, "hand should sit just above the window bottom")
end

local function boundary(object)
	local t = object and object.T
	if not t then return nil end
	return { x = t.x, y = t.y, w = t.w, h = t.h }
end

local function assert_boundary_equal(expected, actual, label)
	T.assert_almost_equal(actual.x, expected.x, 0.001, label .. " x shifted")
	T.assert_almost_equal(actual.y, expected.y, 0.001, label .. " y shifted")
	T.assert_almost_equal(actual.w, expected.w, 0.001, label .. " width changed")
	T.assert_almost_equal(actual.h, expected.h, 0.001, label .. " height changed")
end

T.describe("Stage 1-1 layout stability", function()
	T.it("placement row Y matches after boot and after first jumble play", function()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("app.core.object")
		require("app.bootstrap")
		require("word_game.model.cards.card")
		require("word_game.ui.cardarea")
		require("word_game.model.game")
		require("word_game.model.globals")
		require("app.startup")

		_G.G = Game()
		_G.G:define_constants()
		_G.G.TIMELINE = Scheduler()
		_G.G.INPUT = InputController()
		_G.G:load_card_definitions()
		package.loaded["app.callbacks.settings"] = nil
		require("app.callbacks.settings")
		Dictionary.load()

		G.FUNCS.begin_run()
		for _ = 1, 80 do
			G.TIMERS.REAL = (G.TIMERS.REAL or 0) + 0.016
			G.TIMELINE:advance(0.016)
		end

		T.assert_not_nil(G.placement_table, "placement_table must exist")
		T.assert_not_nil(G.GAME.word_round, "word_round must exist")
		T.assert_equal("jumble", G.GAME.word_round.mode, "stage 1-1 should be jumble")

		local boot_py = placement_y()
		local boot_hy = hand_y()
		local boot_fy = felt_y()
		local boot_hand_boundary = boundary(G.hand)
		local boot_play_boundary = boundary(WORD_GAME.HandShuffle.play_button_uie())
		T.assert_not_nil(boot_py, "placement y must be set after boot")
		assert_hand_bottom_margin()
		for _ = 1, 20 do
			G.TIMERS.REAL = (G.TIMERS.REAL or 0) + 0.016
			G.TIMELINE:advance(0.016)
		end
		assert_boundary_equal(boot_hand_boundary, boundary(G.hand), "hand boundary during startup")
		assert_boundary_equal(boot_play_boundary, boundary(WORD_GAME.HandShuffle.play_button_uie()),
			"play button boundary during startup")
		local boot_area = G.placement_table.area
		T.assert_almost_equal(boot_area.VT.y, boot_py, 0.001,
			"placement VT.y should match T.y immediately after boot")

		-- Place CAT into C_T span and play
		local jumble = require("word_game.model.jumble")
		local j = jumble.state()
		T.assert_not_nil(j, "jumble state required")

		local slots = j.slots
		local span_slot
		for _, slot in ipairs(slots or {}) do
			if slot.kind == "span" then
				span_slot = slot
				break
			end
		end
		T.assert_not_nil(span_slot, "span slot required")

		local letters = { "A", "T" }
		for _, card in ipairs(G.hand.cards or {}) do
			local letter = Dictionary.letter_from_card(card)
			for i, want in ipairs(letters) do
				if letter == want then
					span_slot.cards = span_slot.cards or {}
					span_slot.cards[#span_slot.cards + 1] = card
					G.hand:remove_card(card)
					letters[i] = nil
					break
				end
			end
		end
		jumble.sync_placement_cards(j.slots)
		if G.placement_table then
			G.placement_table:relayout()
		end

		local pre_play_py = placement_y()
		local area = G.placement_table.area
		local pre_vt_y = area.VT and area.VT.y
		local pre_card_y = nil
		for _, card in ipairs(area.cards or {}) do
			pre_card_y = card.VT and card.VT.y
			break
		end

		local flow = require("word_game.model.jumble_play")
		flow.play_jumble_word()

		-- Drain play animation events
		for _ = 1, 200 do
			G.TIMERS.REAL = (G.TIMERS.REAL or 0) + 0.016
			G.TIMELINE:advance(0.016)
		end

		local post_play_py = placement_y()
		local post_vt_y = area.VT and area.VT.y
		local post_card_y = nil
		if G.hand and G.hand.cards and G.hand.cards[1] then
			post_card_y = G.hand.cards[1].VT and G.hand.cards[1].VT.y
		end
		local post_play_hy = hand_y()
		local post_play_fy = felt_y()
		local post_play_hand_boundary = boundary(G.hand)
		local post_play_button_boundary = boundary(WORD_GAME.HandShuffle.play_button_uie())

		T.assert_almost_equal(pre_play_py, boot_py, 0.001, "placement y should not change before play")
		T.assert_almost_equal(pre_vt_y, pre_play_py, 0.001, "placement VT.y should match T.y before play")
		T.assert_almost_equal(post_vt_y, post_play_py, 0.001, "placement VT.y should match T.y after play")
		T.assert_almost_equal(post_play_py, boot_py, 0.001,
			string.format("placement y shifted on play: boot=%.4f pre=%.4f post=%.4f hand boot=%.4f post=%.4f felt boot=%.4f post=%.4f",
				boot_py, pre_play_py, post_play_py, boot_hy, post_play_hy, boot_fy, post_play_fy))
		T.assert_almost_equal(post_play_py, pre_play_py, 0.001,
			"fixed-letter boundary must remain stable after playing a word")
		assert_boundary_equal(boot_hand_boundary, post_play_hand_boundary, "hand boundary")
		assert_boundary_equal(boot_play_boundary, post_play_button_boundary, "play button boundary")
		assert_hand_bottom_margin()
	end)
end)
