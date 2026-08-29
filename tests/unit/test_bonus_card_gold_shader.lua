--[[ tests/unit/test_bonus_card_gold_shader.lua - Bonus card gold face and gold_seal shader ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function read_shader_source()
	local file = io.open("resources/shaders/gold_seal.fs", "r")
	T.assert_not_nil(file, "gold_seal.fs should exist")
	local src = file:read("*a")
	file:close()
	return src
end

local function luminance(rgb)
	return 0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]
end

T.describe("bonus card gold shader (gold_seal.fs)", function()
	T.it("declares Balatro gold_seal clock plus the standard sprite uniforms", function()
		local src = read_shader_source()
		T.assert_not_nil(src:match("uniform vec4 gold_seal"), "must declare gold_seal like Balatro")
		T.assert_not_nil(src:match("uniform float time"), "must declare time so sprite_shader pcall can finish")
		T.assert_not_nil(src:match("uniform vec2 mouse_screen_pos"), "must declare mouse_screen_pos")
		T.assert_not_nil(src:match("gold_seal%.r"), "sparkle must use Balatro gold_seal.r clock")
	end)

	T.it("uses Balatro sparkle math and a travelling beam", function()
		local src = read_shader_source()
		T.assert_not_nil(src:match("sin%(%(texture_coords%.x %* 450"), "Balatro gold-seal sparkle")
		T.assert_not_nil(src:match("beam"), "visible travelling beam")
		T.assert_not_nil(src:match("clock %* 0%.55"), "beam must move with the clock")
	end)

	T.it("emits highlight only so additive blend cannot black out the face", function()
		local src = read_shader_source()
		T.assert_not_nil(src:match("gold %* sparkle"), "overlay should be sparkle highlight, not a replacement fill")
		T.assert_nil(src:match("colour%.rgb %* mask"), "must not rebuild the face from overlay colour")
	end)
end)

T.describe("sprite shader uniform contract", function()
	T.it("only sends dissolve_wipe to the dissolve shader", function()
		local src = io.open("app/core/graphics/sprite_shader.lua", "r"):read("*a")
		T.assert_not_nil(src:match("if _shader == 'dissolve'"), "dissolve_wipe must be dissolve-only")
	end)

	T.it("sends gold_seal as a vec4 clock from G.TIMERS.REAL", function()
		local src = io.open("app/core/graphics/sprite_shader.lua", "r"):read("*a")
		T.assert_not_nil(src:match("sh:send%('gold_seal'"), "gold_seal uniform must be sent explicitly")
		T.assert_not_nil(src:match("G%.TIMERS and G%.TIMERS%.REAL"),
			"clock should include real time so the shimmer animates")
	end)
end)

T.describe("bonus card gold visuals", function()
	mock_env.reset_game()

	local bonus_stack = require("word_game.ui.boss_word_stack")
	local Palette = require("word_game.config.letter_card_palette")
	local DeckColors = require("word_game.config.deck_face_colors")
	local LetterFaces = require("word_game.ui.letter_card_faces")

	T.it("defines a yellow-gold face colour for bonus cards", function()
		T.assert_equal(Palette.BONUS_FACE_COLOR, "gold")
		T.assert_almost_equal(DeckColors.gold[1], 212 / 255, 0.001)
		T.assert_almost_equal(DeckColors.gold[2], 175 / 255, 0.001)
		T.assert_almost_equal(DeckColors.gold[3], 55 / 255, 0.001)
		T.assert_true(DeckColors.gold[1] > 0.7, "gold must read as yellow, not black")
		T.assert_true(DeckColors.gold[2] > 0.5, "gold must have a strong yellow channel")
		T.assert_true(DeckColors.gold[3] < 0.35, "gold must not wash out to white")
	end)

	T.it("gold frame is dark enough for white letter glyphs to read", function()
		local gold = Palette.fill("gold")
		T.assert_true(luminance(gold) < luminance({ 1, 1, 1 }) - 0.15,
			"white glyphs need a noticeably darker gold frame behind them")
	end)

	T.it("apply_gold_bonus_face switches the card to the gold palette", function()
		bonus_stack.clear()
		local applied_color
		local card = {
			ability = { letter = "G" },
			config = { card = { letter = "G", color = "red" } },
			apply_face = function(self, front)
				self.config.card = front
				applied_color = front and front.color
			end,
		}

		G.P_CARDS = G.P_CARDS or {}
		G.P_CARDS.gold_G = {
			letter = "G",
			color = "gold",
			pos = LetterFaces.glyph_pos("G"),
		}

		bonus_stack.apply_gold_bonus_face(card)

		T.assert_equal(applied_color, "gold")
	end)

	T.it("apply_gold_bonus_face clears lingering dissolve colours", function()
		local card = {
			bonus_card = true,
			ability = { letter = "G" },
			config = { card = { letter = "G", color = "red" } },
			dissolve = 1,
			dissolve_wipe = 0.5,
			dissolve_colours = { { 1, 0, 0, 1 }, { 0, 1, 0, 1 } },
			apply_face = function() end,
		}

		G.P_CARDS = G.P_CARDS or {}
		G.P_CARDS.gold_G = { letter = "G", color = "gold", pos = LetterFaces.glyph_pos("G") }

		bonus_stack.apply_gold_bonus_face(card)

		T.assert_equal(card.dissolve, 0)
		T.assert_equal(card.dissolve_wipe, 0)
		T.assert_nil(card.dissolve_colours)
	end)

	T.it("draw_front tints the frame yellow, adds additive gold shimmer, then draws white glyphs", function()
		mock_env.ensure_engine_globals()
		require("word_game.model.cards.card")

		local shader_calls = {}
		local center_dissolve_tint
		local front_dissolve_tint = "unset"
		local blend_modes = {}

		love.graphics.getBlendMode = function()
			return "alpha", "alphamultiply"
		end
		love.graphics.setBlendMode = function(mode)
			blend_modes[#blend_modes + 1] = mode
		end

		local card = {
			bonus_card = true,
			dissolve = 0,
			greyed = false,
			debuff = false,
			edition = nil,
			seal = nil,
			ability = { set = "Default" },
			config = {
				center = { set = "Default", discovered = true },
				card = { letter = "G", color = "gold", pos = LetterFaces.glyph_pos("G") },
			},
			base = { color = "red" },
			children = {
				center = { id = "center" },
				front = {
					apply_shader_effect = function(_, shader)
						if shader == "dissolve" then
							front_dissolve_tint = G.OVERLAY_TINT
						end
						shader_calls[#shader_calls + 1] = "front:" .. shader
					end,
				},
			},
			ARGS = {},
		}
		card.children.center.apply_shader_effect = function(_, shader)
			if shader == "dissolve" then
				center_dissolve_tint = G.OVERLAY_TINT
			end
			shader_calls[#shader_calls + 1] = "center:" .. shader
		end
		setmetatable(card, { __index = Card })

		G.OVERLAY_TINT = nil
		card:draw_front()

		T.assert_equal(shader_calls[1], "center:dissolve",
			"yellow face must use the same dissolve tint path as other letter cards")
		T.assert_equal(shader_calls[2], "center:gold_seal",
			"Balatro-style gold shimmer overlays the yellow face")
		T.assert_equal(shader_calls[3], "front:dissolve",
			"letter glyphs must draw on top so they stay visible")
		T.assert_nil(shader_calls[4])

		local gold = Palette.fill("gold")
		T.assert_not_nil(center_dissolve_tint)
		T.assert_equal(center_dissolve_tint[1], gold[1],
			"bonus frame dissolve must use BONUS_FACE_COLOR, not a stale red/black base")
		T.assert_nil(front_dissolve_tint, "glyphs must stay white, not gold-tinted")
		T.assert_equal(blend_modes[1], "add", "gold shimmer must be additive so it cannot replace the yellow face")
		T.assert_equal(blend_modes[2], "alpha", "blend mode must be restored before glyphs draw")
	end)

	T.it("shader gold_seal and time uniforms advance between frames", function()
		mock_env.ensure_engine_globals()
		require("app.core.graphics.sprite")

		G.CANVAS_SCALE = 1
		G.TILESCALE = 1
		G.TILESIZE = 20
		G.INPUT = G.INPUT or { cursor_position = { x = 0, y = 0 } }
		G.C = G.C or {}
		G.C.CLEAR = G.C.CLEAR or { 0, 0, 0, 0 }

		local sent_gold = {}
		local sent_times = {}
		local sprite = Sprite(0, 0, 1, 1, {
			name = "ui_1",
			px = 4,
			py = 4,
			image = { getDimensions = function() return 4, 4 end },
		}, { x = 0, y = 0 })
		sprite:set_role({ draw_major = { ID = 7, dissolve = 0 } })

		G.SHADERS.gold_seal = {
			send = function(_, name, value)
				if name == "time" then
					sent_times[#sent_times + 1] = value
				elseif name == "gold_seal" then
					sent_gold[#sent_gold + 1] = value[1]
				end
			end,
		}

		G.TIMERS.REAL = 1.0
		sprite:apply_shader_effect("gold_seal", nil, nil, nil, nil)

		G.TIMERS.REAL = 2.5
		sprite:apply_shader_effect("gold_seal", nil, nil, nil, nil)

		T.assert_equal(#sent_gold, 2, "gold_seal.r must be sent each frame")
		T.assert_true(sent_gold[2] > sent_gold[1], "gold_seal.r must advance so Balatro sparkle animates")
		T.assert_equal(#sent_times, 2)
		T.assert_true(sent_times[2] > sent_times[1], "time uniform must also advance")
	end)
end)
