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
	end)

	T.it("sweeps in card-local UV like Balatro voucher/foil, not atlas texture_coords", function()
		local src = read_shader_source()
		T.assert_not_nil(src:match("card_uv"), "must convert atlas coords into 0-1 card UV")
		T.assert_not_nil(src:match("texture_details%.xy"), "UV must subtract the sprite cell origin")
		T.assert_not_nil(src:match("texture_details%.ba"), "UV must divide by the sprite cell size")
		T.assert_nil(src:match("fract%(texture_coords"), "sweep must not use raw atlas texture_coords")
	end)

	T.it("animates from the time uniform so a stuck gold_seal clock cannot freeze the sweep", function()
		local src = read_shader_source()
		T.assert_not_nil(src:match("float clock = time"), "sweep clock must be the time uniform")
		T.assert_not_nil(src:match("clock %* SWEEP_SPEED"), "band must subtract clock so it travels")
		T.assert_not_nil(src:match("pixel%.a %* shine"), "stripe must use alpha so it is visible on the yellow face")
	end)
end)

T.describe("gold shimmer sweep motion", function()
	-- Keep in lockstep with SWEEP_* in resources/shaders/gold_seal.fs
	local SWEEP_X, SWEEP_Y, SWEEP_SPEED = 0.85, 0.45, 0.233

	local function fract(x)
		return x - math.floor(x)
	end

	local function beam(uvx, uvy, clock)
		local phase = fract(uvx * SWEEP_X + uvy * SWEEP_Y - clock * SWEEP_SPEED)
		local ridge = 1 - math.abs(phase - 0.5) * 2
		if ridge < 0 then ridge = 0 end
		return ridge ^ 3
	end

	T.it("moves the highlight peak across the card as time advances", function()
		local function peak_x(clock)
			local best_x, best = 0, -1
			for i = 0, 20 do
				local x = i / 20
				local b = beam(x, 0.5, clock)
				if b > best then
					best, best_x = b, x
				end
			end
			return best_x, best
		end

		local x0, b0 = peak_x(0)
		local x1, b1 = peak_x(2.4)
		T.assert_true(b0 > 0.3, "there must be a bright band at t=0")
		T.assert_true(b1 > 0.3, "there must be a bright band after the clock advances")
		T.assert_true(math.abs(x1 - x0) > 0.2,
			"the bright band must travel across the card, not pulse in place")
	end)

	T.it("is bright on one side of the card and dark on the other at a frozen clock", function()
		local brightest, darkest = -1, 2
		for i = 0, 20 do
			local b = beam(i / 20, 0.5, 0)
			if b > brightest then brightest = b end
			if b < darkest then darkest = b end
		end
		T.assert_true(brightest - darkest > 0.5,
			"a travelling shimmer must not light the whole face evenly")
	end)
end)

T.describe("sprite shader uniform contract", function()
	T.it("only sends dissolve_wipe to the dissolve shader", function()
		local src = io.open("app/core/graphics/sprite_shader.lua", "r"):read("*a")
		T.assert_not_nil(src:match("if _shader == 'dissolve'"), "dissolve_wipe must be dissolve-only")
	end)

	T.it("sends gold_seal time in a separate pcall from G.TIMERS.REAL", function()
		local src = io.open("app/core/graphics/sprite_shader.lua", "r"):read("*a")
		T.assert_not_nil(src:match("if _shader == 'gold_seal' then"),
			"gold_seal clock must be sent even if earlier uniforms fail")
		T.assert_not_nil(src:match("sh:send%('time', clock%)"),
			"gold_seal must send time as REAL so the stripe moves on a still card")
		T.assert_not_nil(src:match("sh:send%('gold_seal', clock, clock, 0, 1%)"),
			"gold_seal vec4 must be four numbers, not a 2-value table")
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

	T.it("become_bonus_card flags the card and switches it to gold before any fly", function()
		local applied_color
		local card = {
			ability = { letter = "V", bonus = 0 },
			config = { card = { letter = "V", color = "red" } },
			apply_face = function(self, front)
				self.config.card = front
				applied_color = front and front.color
			end,
		}
		G.P_CARDS = G.P_CARDS or {}
		G.P_CARDS.gold_V = { letter = "V", color = "gold", pos = LetterFaces.glyph_pos("V") }

		bonus_stack.become_bonus_card(card)

		T.assert_true(card.bonus_card)
		T.assert_equal(applied_color, "gold")
		T.assert_equal(card.ability.bonus, bonus_stack.BONUS_POINTS)
	end)

	T.it("gold transform rematerializes as a shimmer bonus card before flying to the gutter", function()
		local DissolveFX = require("app.effects.dissolve_fx")
		local orig_run = DissolveFX.run
		local gold_before_fly = false
		local shimmer_before_fly = false
		local flew = false

		DissolveFX.run = function(target, opts)
			if opts.on_finish then
				if opts.mode == "in" then
					gold_before_fly = target.config and target.config.card and target.config.card.color == "gold"
					shimmer_before_fly = target.bonus_card == true
				end
				opts.on_finish(target)
			end
		end

		local card = {
			ability = { letter = "E", bonus = 0, set = "Default" },
			config = { card = { letter = "E", color = "red" } },
			T = { x = 8, y = 4, w = 2, h = 2.8, r = 0 },
			VT = { x = 8, y = 4, w = 2, h = 2.8, r = 0 },
			states = { visible = true, drag = { can = true, is = false }, collide = { can = true } },
			apply_face = function(self, front)
				self.config.card = front
			end,
			hard_set_T = function(self, nx, ny, nw, nh)
				self.T.x, self.T.y, self.T.w, self.T.h = nx, ny, nw, nh
			end,
		}
		G.P_CARDS = G.P_CARDS or {}
		G.P_CARDS.gold_E = { letter = "E", color = "gold", pos = LetterFaces.glyph_pos("E") }

		G.TIMELINE = { enqueue = function() end }
		G.TIMERS = G.TIMERS or { REAL = 0 }

		bonus_stack.clear()
		G.CARD_W, G.CARD_H = 2, 2.8
		G.ROOM = G.ROOM or { T = { x = 1, y = 0, w = 20, h = 11.5 } }
		G.hand = G.hand or { T = { x = 3.2, y = 8.0, w = 10.5, h = 2.8 } }
		G.placement_table = G.placement_table or {
			area = { T = { x = 0.6, y = 2.0, w = 18.0, h = 2.8 } },
		}

		bonus_stack.stage_cards({ card })
		bonus_stack.animate_cards_to_stack(function(tween)
			if type(tween) == "table" and tween.func then
				tween.func()
			end
		end, nil, {
			initial_delay = 0,
			card_delay = 0,
			stagger = 0,
			hold = 0,
			on_complete = function()
				flew = true
			end,
		})

		DissolveFX.run = orig_run

		T.assert_true(shimmer_before_fly, "bonus_card (gold shimmer) must be set before the gutter fly")
		T.assert_true(gold_before_fly, "gold face must be applied before the gutter fly")
		T.assert_true(card.bonus_card)
		T.assert_equal(card.config.card.color, "gold")
		T.assert_true(flew)
	end)

	T.it("draw_front tints the frame yellow, overlays gold shimmer, then draws white glyphs", function()
		mock_env.ensure_engine_globals()
		require("word_game.model.cards.card")

		local shader_calls = {}
		local center_dissolve_tint
		local front_dissolve_tint = "unset"

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
		card.children.center.apply_shader_effect = function(_, shader, ...)
			if shader == "dissolve" then
				local args = { ... }
				center_dissolve_tint = args[11] or G.OVERLAY_TINT
			end
			shader_calls[#shader_calls + 1] = "center:" .. shader
		end
		setmetatable(card, { __index = Card })

		G.OVERLAY_TINT = nil
		card:draw_front()

		T.assert_equal(shader_calls[1], "center:dissolve",
			"yellow face must use the same dissolve tint path as other letter cards")
		T.assert_equal(shader_calls[2], "center:gold_seal",
			"gold shimmer overlays the yellow face")
		T.assert_equal(shader_calls[3], "front:dissolve",
			"letter glyphs must draw on top so they stay visible")
		T.assert_nil(shader_calls[4])

		local gold = Palette.fill("gold")
		T.assert_not_nil(center_dissolve_tint)
		T.assert_equal(center_dissolve_tint[1], gold[1],
			"bonus frame dissolve must use BONUS_FACE_COLOR, not a stale red/black base")
		T.assert_nil(front_dissolve_tint, "glyphs must stay white, not gold-tinted")
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
			send = function(_, name, ...)
				if name == "time" then
					sent_times[#sent_times + 1] = select(1, ...)
				elseif name == "gold_seal" then
					sent_gold[#sent_gold + 1] = select(1, ...)
				end
			end,
		}

		G.TIMERS.REAL = 1.0
		sprite:apply_shader_effect("gold_seal", nil, nil, nil, nil)

		G.TIMERS.REAL = 2.5
		sprite:apply_shader_effect("gold_seal", nil, nil, nil, nil)

		T.assert_equal(#sent_gold, 2, "gold_seal clock must be sent each frame")
		T.assert_true(sent_gold[2] > sent_gold[1], "gold_seal clock must advance on a still card")
		T.assert_equal(#sent_times, 2)
		T.assert_true(sent_times[2] > sent_times[1], "time uniform must advance with G.TIMERS.REAL")
		T.assert_almost_equal(sent_times[1], 1.0, 0.001)
		T.assert_almost_equal(sent_times[2], 2.5, 0.001)
	end)
end)
