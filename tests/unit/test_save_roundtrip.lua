--[[ tests/unit/test_save_roundtrip.lua - Card / CardArea / pack save contract ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("save round-trip", function()
	mock_env.reset_game()
	mock_env.ensure_card_class()
	require("word_game.model.game")
	require("word_game.model.cards.definitions")
	require("word_game.ui.cardarea.init")
	local pack = require("app.core.util.pack")
	require("app.core.persistence.save")
	pack_to_source = pack.pack_to_source
	unpack_source = pack.unpack_source
	read_save_payload = pack.read_save_payload
	write_save_file = pack.write_save_file
	save_safe_clone = require("app.core.util.tables").save_safe_clone

	G.HIGHLIGHT_H = G.HIGHLIGHT_H or 0.2
	G.VERSION = G.VERSION or "test"
	local atlas = {
		px = 71,
		py = 95,
		name = "stub",
		image = { getDimensions = function() return 923, 190 end },
	}
	G.TEXTURE_ATLASES = G.TEXTURE_ATLASES or {}
	G.TEXTURE_ATLASES.letters = atlas
	G.TEXTURE_ATLASES.letter_frame = atlas
	G.TEXTURE_ATLASES.centers = atlas
	G.TEXTURE_ATLASES.playing_back = atlas

	G.load_card_definitions = Game.load_card_definitions
	G:load_card_definitions()

	local function make_letter(letter, playing_card)
		local front = G.LETTERS.faces["red_" .. letter]
		local card = Card(0, 0, G.CARD_W, G.CARD_H, front, G.LETTERS.centers.letter_base, {
			playing_card = playing_card,
			bypass_discovery_center = true,
			bypass_discovery_ui = true,
			bypass_lock = true,
		})
		card.ability.letter = letter
		card.config.center_key = "letter_base"
		card.config.card_key = "red_" .. letter
		card.selected = playing_card == 2
		return card
	end

	T.it("Card:save / Card:load restores letter identity and versioned payload", function()
		local original = make_letter("Q", 7)
		local payload = original:save()
		T.assert_equal(payload.version, Card.SAVE_VERSION)
		T.assert_equal(payload.refs.center, "letter_base")
		T.assert_equal(payload.refs.card, "red_Q")
		T.assert_equal(payload.state.ability.letter, "Q")
		T.assert_equal(payload.state.playing_card, 7)

		local packed = pack_to_source({ card = payload })
		local unpacked = unpack_source(packed)
		local restored = Card(0, 0, G.CARD_W, G.CARD_H, G.LETTERS.faces.empty, G.LETTERS.centers.letter_base, {
			bypass_discovery_center = true,
			bypass_discovery_ui = true,
			bypass_lock = true,
		})
		restored:load(unpacked.card)
		T.assert_equal(restored.config.center_key, "letter_base")
		T.assert_equal(restored.config.card_key, "red_Q")
		T.assert_equal(restored.ability.letter, "Q")
		T.assert_equal(restored.playing_card, 7)
	end)

	T.it("CardArea:save / load and restore_card_areas rebuild the hand", function()
		G.hand = CardArea(0, 0, 8, 2, { type = "hand", card_limit = 7, selection_limit = 1 })
		G.hand:emplace(make_letter("C", 1))
		G.hand:emplace(make_letter("A", 2))
		T.assert_equal(#G.hand.cards, 2)

		local area_blob = G.hand:save()
		T.assert_equal(#area_blob.cards, 2)
		T.assert_equal(area_blob.cards[1].state.ability.letter, "C")
		T.assert_equal(area_blob.cards[2].state.ability.letter, "A")

		local snapshot = {
			STATE = G.STATES.TABLE_BOARD,
			cardAreas = { hand = area_blob },
		}
		local source = pack_to_source(snapshot)
		local loaded = unpack_source(source)

		G.deck, G.discard, G.placement_table = nil, nil, nil
		G.hand = CardArea(0, 0, 8, 2, { type = "hand", card_limit = 7, selection_limit = 1 })
		restore_card_areas(loaded)
		T.assert_equal(#G.hand.cards, 2)
		T.assert_equal(G.hand.cards[1].ability.letter, "C")
		T.assert_equal(G.hand.cards[2].ability.letter, "A")
		T.assert_equal(G.hand.cards[1].playing_card, 1)
		T.assert_equal(G.hand.cards[2].playing_card, 2)
		local indexed = 0
		for _, card in ipairs(G.hand.cards) do
			if card.playing_card then
				indexed = indexed + 1
			end
		end
		T.assert_equal(indexed, 2)
	end)

	T.it("save_safe_clone replaces live engine objects then pack/unpack round-trips", function()
		local Kind = require("app.core.object")
		local live = CardArea(0, 0, 1, 1, { type = "deck" })
		T.assert_true(live:is_kind(Kind))
		local cloned = save_safe_clone({
			GAME = { chips = 42, word_round = { puzzle_index = 3 } },
			STATE = 1,
			hand = live,
			nested = { keep = "yes", area = live },
		})
		T.assert_equal(cloned.GAME.chips, 42)
		T.assert_equal(cloned.GAME.word_round.puzzle_index, 3)
		T.assert_equal(cloned.hand, '"MANUAL_REPLACE"')
		T.assert_equal(cloned.nested.area, '"MANUAL_REPLACE"')
		T.assert_equal(cloned.nested.keep, "yes")

		local round_tripped = unpack_source(pack_to_source(cloned))
		T.assert_equal(round_tripped.GAME.chips, 42)
		T.assert_equal(round_tripped.hand, '"MANUAL_REPLACE"')
	end)

	T.it("write_save_file / read_save_payload compress and restore a run snapshot", function()
		local path = "test_roundtrip_save.acs"
		local snapshot = {
			VERSION = "test",
			STATE = G.STATES.TABLE_BOARD,
			GAME = { chips = 99, seed_streams = { seed = "ABCD1234" } },
			cardAreas = {
				hand = {
					config = { type = "hand" },
					cards = { make_letter("T", 4):save() },
				},
			},
		}
		write_save_file(path, snapshot)
		local source = read_save_payload(path)
		T.assert_not_nil(source)
		T.assert_equal(string.sub(source, 1, 6), "return")
		local restored = unpack_source(source)
		T.assert_equal(restored.GAME.chips, 99)
		T.assert_equal(restored.GAME.seed_streams.seed, "ABCD1234")
		T.assert_equal(restored.cardAreas.hand.cards[1].state.ability.letter, "T")
		T.assert_equal(restored.cardAreas.hand.cards[1].state.playing_card, 4)
		love.filesystem.remove(path)
	end)

	T.it("restores a jumble hand snapshot from disk via round.restore_from_save", function()
		local jumble_fixture = require("tests.helpers.jumble_save_fixture")
		local round = require("word_game.model.round")
		mock_env.install_presentation({
			ScoreBanner = {
				reset = function() end,
				state = function() return { to_go_label = "SCORE", target = 0, remaining = 0 } end,
				reset_jumble_score = function() end,
				snap_to_actual = function() end,
				set_banner_mode = function() end,
				hide_points_to_get_display = function() end,
				sync_points_to_get_preview = function() end,
			},
			TimelineTimer = { reset_progress = function() end, reset = function() end },
			StageLabel = { force_sync = function() end },
			Sidebar = { ensure = function() end, refresh = function() end },
			BonusStackUI = { on_hand_start = function() end },
		})

		G.hand = CardArea(0, 0, 8, 2, { type = "hand", card_limit = 7, selection_limit = 1 })
		local path = jumble_fixture.write_temp("test_jumble_hand_save.acs", write_save_file, make_letter("R", 9):save())
		local loaded = jumble_fixture.read_temp(path, read_save_payload, unpack_source)
		T.assert_not_nil(loaded)
		jumble_fixture.apply_loaded(loaded, restore_card_areas, round.restore_from_save)

		local wr = G.GAME.word_round
		T.assert_equal(wr.mode, "jumble")
		T.assert_equal(wr.set, 2)
		T.assert_equal(wr.jumble.total_score, 18)
		T.assert_equal(G.GAME.timeline_seconds, 60, "restore_from_save resets fuse via timeline_reset")
		T.assert_equal(#G.hand.cards, 1)
		T.assert_equal(G.hand.cards[1].ability.letter, "R")
		love.filesystem.remove(path)
	end)
end)
