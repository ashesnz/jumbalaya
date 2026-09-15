--[[ tests/unit/test_letter_card_visuals.lua - Letter hand card draw regressions ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

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
		edition = nil,
		seal = nil,
		ambient_tilt = 0.2,
		selected = false,
		inspecting = false,
		states = {
			hover = { is = false },
			focus = { is = overrides.focused or false },
			drag = { is = false },
			visible = true,
			collide = { can = true },
		},
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
				apply_shader_effect = function(_, shader, ...)
					if shader == "dissolve" then
						local args = { ... }
						center_calls[#center_calls + 1] = args[11]
					end
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
		draw_shadow = function() end,
		draw_market_widgets = function() end,
		draw_leftover_children = function() end,
		draw_boundingrect = function() end,
	}
	setmetatable(card, { __index = Card })
	return card, center_calls, front_calls, function() return focused_draws end
end

T.describe("letter card visuals", function()
	mock_env.ensure_card_class()

	T.it("draw_front tints the frame via dissolve and keeps glyphs white", function()
		local card, center_tints, front_shaders = stub_letter_card()
		card:draw_front()

		T.assert_equal(#center_tints, 1, "letter frame must use dissolve tint")
		T.assert_equal(#front_shaders, 1, "glyph layer must use dissolve")
		T.assert_equal(front_shaders[1], "dissolve")

		local expected = LetterPalette.fill("red")
		T.assert_equal(center_tints[1][1], expected[1])
		T.assert_equal(center_tints[1][2], expected[2])
		T.assert_equal(center_tints[1][3], expected[3])
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
			states = {
				hover = { is = false },
				click = { is = false },
				drag = { is = false },
			},
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
		game.shared_shadow = { apply_shader_effect = function() end }
		game.SETTINGS = game.SETTINGS or { GRAPHICS = { shadows = "Off" } }

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
