--[[ tests/unit/test_letter_card_visuals.lua - Letter hand card draw regressions ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

local InputFlags = require("jumbalaya-engine.scene.input_flags")
local LetterFaces = require("word_game.ui.cards.letter_faces")
local LetterPalette = require("word_game.config.visuals.letter_card_palette")
local chrome = require("word_game.ui.cardarea.chrome")

local function stub_letter_card(overrides)
	overrides = overrides or {}
	local center_calls = {}
	local front_calls = {}
	local focused_draws = 0

	local card = {
		bonus_card = overrides.bonus_card,
		dissolve = 0,
		greyed = false,
		debuff = false,
		ambient_tilt = 0.2,
		selected = false,
		inspecting = false,
		states = InputFlags.new(),
		ability = { set = "Default", letter_color = overrides.letter_color or "red" },
		config = {
			center = { set = "Default", discovered = true },
			card = { letter = overrides.letter or "A", color = overrides.color or "red" },
		},
		base = { color = overrides.color or "red" },
		area = overrides.area,
		sprite_facing = "front",
		children = {
			center = {
				atlas = overrides.center_atlas or { name = "letter_frame" },
				apply_shader_effect = function(_, shader, ...)
					local args = { ... }
					center_calls[#center_calls + 1] = {
						shader = shader,
						overlay = args[11],
					}
				end,
			},
			front = {
				apply_shader_effect = function(_, shader)
					front_calls[#front_calls + 1] = shader
				end,
			},
			focused_ui = {
				draw = function()
					focused_draws = focused_draws + 1
				end,
			},
		},
		ARGS = {},
		T = { x = 0, y = 0, w = 1, h = 1.4, r = 0, scale = 1 },
		VT = { x = 0, y = 0, w = 1, h = 1.4, r = 0, scale = 1 },
		shadow_parallax = { x = 0, y = 0 },
		tilt_var = { mx = 0, my = 0, dx = 0, dy = 0, amt = 0 },
		hover_tilt = 1,
		is_shader_idle = function() return false end,
		sync_shadow_state = function() end,
		update_tilt = function() end,
		draw_market_widgets = function() end,
		draw_leftover_children = function() end,
		draw_boundingrect = function() end,
	}
	setmetatable(card, { __index = Card })
	card.states.focused = overrides.focused or false
	card.states.collideable = true
	return card, center_calls, front_calls, function() return focused_draws end
end

T.describe("letter card visuals", function()
	mock_env.ensure_card_class()

	T.it("draw_front tints the frame via dissolve and keeps glyphs white", function()
		local card, center_tints, front_shaders = stub_letter_card()
		card:draw_front()

		T.assert_equal(#center_tints, 1, "letter frame must use dissolve tint")
		T.assert_equal(center_tints[1].shader, "dissolve")
		T.assert_equal(#front_shaders, 1, "glyph layer must use dissolve")
		T.assert_equal(front_shaders[1], "dissolve")

		local expected = LetterPalette.fill("red")
		T.assert_equal(center_tints[1].overlay[1], expected[1])
		T.assert_equal(center_tints[1].overlay[2], expected[2])
		T.assert_equal(center_tints[1].overlay[3], expected[3])
	end)

	T.it("tints JumbalayaCardFrame with every playable face colour", function()
		for _, color in ipairs({ "red", "black", "modified", "gold" }) do
			local card, center_tints = stub_letter_card({ color = color, letter_color = color })
			card:draw_front()
			T.assert_equal(#center_tints, 1, color .. " frame must be tinted")
			local expected = LetterPalette.fill(color)
			T.assert_equal(center_tints[1].overlay[1], expected[1], color .. " r")
			T.assert_equal(center_tints[1].overlay[2], expected[2], color .. " g")
			T.assert_equal(center_tints[1].overlay[3], expected[3], color .. " b")
			T.assert_true(
				center_tints[1].overlay[1] ~= 1 or center_tints[1].overlay[2] ~= 1 or center_tints[1].overlay[3] ~= 1,
				color .. " must not show the raw white card frame")
		end
	end)

	T.it("tints bonus cards with the gold face colour while playing", function()
		local card, center_tints = stub_letter_card({ bonus_card = true, color = "red" })
		card:draw_front()
		local gold = LetterPalette.fill(LetterPalette.BONUS_FACE_COLOR)
		local dissolve = center_tints[1]
		T.assert_not_nil(dissolve)
		T.assert_equal(dissolve.shader, "dissolve")
		T.assert_equal(dissolve.overlay[1], gold[1])
		T.assert_equal(dissolve.overlay[2], gold[2])
		T.assert_equal(dissolve.overlay[3], gold[3])
	end)

	T.it("tints the letter_frame atlas even when the face letter is only on ability", function()
		local card, center_tints = stub_letter_card({ color = "black", letter_color = "black" })
		card.config.card = {}
		card.ability.letter = "B"
		card.ability.letter_color = "black"
		card.base.color = nil
		card:draw_front()
		local expected = LetterPalette.fill("black")
		T.assert_equal(center_tints[1].overlay[1], expected[1])
		T.assert_equal(center_tints[1].overlay[2], expected[2])
		T.assert_equal(center_tints[1].overlay[3], expected[3])
	end)

	T.it("keeps the palette tint on greyed played cards", function()
		local card, center_tints = stub_letter_card({ color = "modified", letter_color = "modified" })
		card.greyed = true
		card:draw_front()
		T.assert_equal(#center_tints, 1)
		T.assert_equal(center_tints[1].shader, "played")
		local expected = LetterPalette.fill("modified")
		T.assert_equal(center_tints[1].overlay[1], expected[1])
		T.assert_equal(center_tints[1].overlay[2], expected[2])
		T.assert_equal(center_tints[1].overlay[3], expected[3])
	end)

	T.it("resolves face colour from the card", function()
		local gold = LetterPalette.fill("gold")
		local tint = LetterFaces.tint_for_card({
			base = { color = "gold" },
			config = { card = { letter = "C", color = "gold" } },
		})
		T.assert_equal(tint[1], gold[1])
		T.assert_equal(tint[2], gold[2])
		T.assert_equal(tint[3], gold[3])
	end)

	T.it("applies the palette tint during a full play draw", function()
		mock_env.setup()
		local game = shell.game()
		game.dealt_letters = { config = { type = "hand" } }

		local card, center_tints = stub_letter_card({
			area = game.dealt_letters,
			color = "gold",
			letter_color = "gold",
		})
		card:draw("card")
		T.assert_equal(center_tints[1].shader, "dissolve")
		local expected = LetterPalette.fill("gold")
		T.assert_equal(center_tints[1].overlay[1], expected[1])
		T.assert_equal(center_tints[1].overlay[2], expected[2])
		T.assert_equal(center_tints[1].overlay[3], expected[3])
	end)

	T.it("composites marketplace fly frames with the face colour, not the raw mask", function()
		mock_env.setup()
		local colors = {}
		local orig_love = love
		love = {
			graphics = {
				newQuad = function() return {} end,
				setColor = function(r, g, b)
					colors[#colors + 1] = { r, g, b }
				end,
				draw = function() end,
			},
		}
		local game = shell.game()
		game.TEXTURE_ATLASES = {
			letter_frame = {
				name = "letter_frame",
				image = { getDimensions = function() return 71, 95 end },
				px = 71,
				py = 95,
			},
			letters = {
				name = "letters",
				image = { getDimensions = function() return 923, 190 end },
				px = 71,
				py = 95,
			},
		}
		local ok, err = pcall(function()
			LetterFaces.draw_composite(0, 0, 0, 71, 95, "A", "black", 1)
		end)
		love = orig_love
		T.assert_true(ok, tostring(err))
		local expected = LetterPalette.fill("black")
		T.assert_equal(colors[1][1], expected[1])
		T.assert_equal(colors[1][2], expected[2])
		T.assert_equal(colors[1][3], expected[3])
		T.assert_equal(colors[2][1], 1)
		T.assert_equal(colors[2][2], 1)
		T.assert_equal(colors[2][3], 1)
	end)

	T.it("does not draw a drop shadow under letter cards", function()
		mock_env.setup()
		local game = shell.game()
		game.dealt_letters = { config = { type = "hand" } }
		game.SETTINGS = { GRAPHICS = { shadows = "On" } }
		T.assert_nil(Card.draw_shadow)
		local card, center_tints = stub_letter_card({ area = game.dealt_letters })
		card:draw("both")
		T.assert_equal(#center_tints, 1)
		T.assert_not_nil(center_tints[1].overlay)
	end)

	T.it("hides the playing-back sprite while the letter face is showing", function()
		mock_env.setup()
		local game = shell.game()
		game.dealt_letters = { config = { type = "hand" } }

		local card, center_tints = stub_letter_card({ area = game.dealt_letters })
		card.children.back = { states = { visible = true } }
		card.sprite_facing = "front"
		card:draw("card")
		T.assert_false(card.children.back.states.visible, "card back must not peek around the tinted frame")
		T.assert_not_nil(center_tints[1].overlay)
		local expected = LetterPalette.fill("red")
		T.assert_equal(center_tints[1].overlay[1], expected[1])
	end)

	T.it("set_sprites assigns the letter_frame atlas to the center sprite", function()
		mock_env.setup()
		local game = shell.game()
		game.TEXTURE_ATLASES = game.TEXTURE_ATLASES or {}
		game.TEXTURE_ATLASES.letter_frame = {
			name = "letter_frame",
			image = { getDimensions = function() return 71, 95 end },
			px = 71,
			py = 95,
		}
		game.TEXTURE_ATLASES.letters = {
			name = "letters",
			image = { getDimensions = function() return 923, 190 end },
			px = 71,
			py = 95,
		}
		game.TEXTURE_ATLASES.centers = game.TEXTURE_ATLASES.letter_frame
		game.LETTERS = game.LETTERS or { centers = { deck_alpha = { pos = { x = 0, y = 0 } } } }

		local card = {
			T = { x = 0, y = 0, w = 1, h = 1.4 },
			states = InputFlags.new(),
			config = {
				center = { set = "Default", atlas = "letter_frame", pos = { x = 0, y = 0 } },
				card = { letter = "Z", color = "red" },
			},
			children = {},
			back = "selected_back",
			params = {},
		}
		setmetatable(card, { __index = Card })
		card:set_sprites(card.config.center, card.config.card)

		T.assert_not_nil(card.children.center)
		T.assert_equal(card.children.center.atlas.name, "letter_frame")
		T.assert_not_nil(card.children.front)
		T.assert_equal(card.children.front.atlas.name, "letters")
		T.assert_equal(card.children.center.scale.x, card.children.front.scale.x)
		T.assert_equal(card.children.center.scale.y, card.children.front.scale.y)
	end)

	T.it("does not create hand focus chrome for dealt letter cards", function()
		mock_env.setup()
		local game = shell.game()
		game.TEXTURE_ATLASES = game.TEXTURE_ATLASES or {}
		game.TEXTURE_ATLASES.letter_frame = {
			name = "letter_frame",
			image = { getDimensions = function() return 71, 95 end },
			px = 71,
			py = 95,
		}
		game.TEXTURE_ATLASES.letters = {
			name = "letters",
			image = { getDimensions = function() return 923, 190 end },
			px = 71,
			py = 95,
		}
		game.dealt_letters = { config = { type = "hand" } }
		require("word_game.ui.cards.popups")

		local card = {
			T = { x = 0, y = 0, w = 1, h = 1.4 },
			VT = { x = 0, y = 0, w = 0, h = 0 },
			area = game.dealt_letters,
			ability = { set = "Default" },
			children = {},
		}

		T.assert_nil(game.DEFINITIONS.card_focus_ui(card))
	end)

	T.it("does not draw focused_ui on dealt hand cards even if one exists", function()
		mock_env.setup()
		local game = shell.game()
		game.dealt_letters = { config = { type = "hand" } }

		local card, _, _, focused_draws = stub_letter_card({ area = game.dealt_letters })
		card:draw("card")
		T.assert_equal(focused_draws(), 0, "hand cards must not paint focus chrome")
	end)

	T.it("skips hand area chrome padding behind cards", function()
		mock_env.setup()
		local game = shell.game()
		local hand = { config = { type = "hand" }, children = {} }
		game.dealt_letters = hand
		T.assert_true(chrome.skip_chrome(hand))
	end)
end)
