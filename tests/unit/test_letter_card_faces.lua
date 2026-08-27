--[[ tests/unit/test_letter_card_faces.lua - Runtime letter card atlas layout ]]

local T = require("tests.framework")

T.describe("letter card faces", function()
	local LetterFaces = require("word_game.ui.letter_card_faces")
	local Palette = require("word_game.config.letter_card_palette")

	T.it("maps A–M to row 0 and N–Z to row 1", function()
		T.assert_equal(LetterFaces.glyph_pos("A").x, 0)
		T.assert_equal(LetterFaces.glyph_pos("A").y, 0)
		T.assert_equal(LetterFaces.glyph_pos("M").x, 12)
		T.assert_equal(LetterFaces.glyph_pos("N").x, 0)
		T.assert_equal(LetterFaces.glyph_pos("N").y, 1)
		T.assert_equal(LetterFaces.glyph_pos("Z").x, 12)
		T.assert_equal(LetterFaces.glyph_pos("Z").y, 1)
	end)

	T.it("shares glyph positions across red and black faces", function()
		G.P_CARDS = G.P_CARDS or {}
		local pos = LetterFaces.glyph_pos("Q")
		G.P_CARDS.red_Q = { letter = "Q", color = "red", atlas = "letters", pos = pos }
		G.P_CARDS.black_Q = { letter = "Q", color = "black", atlas = "letters", pos = pos }
		local red = G.P_CARDS.red_Q
		local black = G.P_CARDS.black_Q
		T.assert_equal(red.pos.x, black.pos.x)
		T.assert_equal(red.pos.y, black.pos.y)
		T.assert_equal(red.atlas, "letters")
		T.assert_equal(red.color, "red")
		T.assert_equal(black.color, "black")
	end)

	T.it("uses #7e1011 as the default startup face colour", function()
		local DeckColors = require("word_game.config.deck_face_colors")
		local Palette = require("word_game.config.letter_card_palette")
		T.assert_equal(Palette.DEFAULT_FACE_COLOR, "red")
		T.assert_true(math.abs(DeckColors.red[1] - 126 / 255) < 0.0001)
		T.assert_true(math.abs(DeckColors.red[2] - 16 / 255) < 0.0001)
		T.assert_true(math.abs(DeckColors.red[3] - 17 / 255) < 0.0001)
		T.assert_true(math.abs(Palette.fill("red", false)[1] - 126 / 255) < 0.0001)
	end)

	T.it("uses #16151a for modified marketplace cards", function()
		local DeckColors = require("word_game.config.deck_face_colors")
		local Palette = require("word_game.config.letter_card_palette")
		T.assert_equal(Palette.MODIFIED_FACE_COLOR, "modified")
		T.assert_true(math.abs(DeckColors.modified[1] - 22 / 255) < 0.0001)
		T.assert_true(math.abs(DeckColors.modified[2] - 21 / 255) < 0.0001)
		T.assert_true(math.abs(DeckColors.modified[3] - 26 / 255) < 0.0001)
		T.assert_equal(Palette.fill("modified", false)[1], DeckColors.modified[1])
	end)

	T.it("switches palette fills for colourblind mode", function()
		local normal = Palette.fill("red", false)
		local cb = Palette.fill("red", true)
		T.assert_true(normal[1] ~= cb[1] or normal[2] ~= cb[2], "Colourblind red should differ from default")
	end)
end)
