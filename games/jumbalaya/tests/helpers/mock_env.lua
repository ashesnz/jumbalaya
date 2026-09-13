--[[ tests/helpers/mock_env.lua
     Headless test environment — shell via jumbalaya-engine.shell (no global G).
]]

local M = {}

local shell = require("jumbalaya-engine.shell")

local function shell_game()
	local game = shell.game()
	if not game then
		shell.bind_game({})
		game = shell.game()
	end
	return game
end

local function stub_atlas()
	return {
		px = 4,
		py = 4,
		image = { getDimensions = function() return 4, 4 end },
	}
end

--- Load real engine classes (AnimNode, Sprite, etc.) so tests never use stub moveables.
function M.ensure_engine_globals()
	if not package.loaded["bootstrap_paths"] then
		require("bootstrap_paths").install()
	end

	local S = shell_game()
	_G.WORD_GAME = _G.WORD_GAME or {}
	_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
	S.SETTINGS = S.SETTINGS or {
		paused = false,
		GRAPHICS = { shadows = "Off", texture_scaling = 1 },
	}
	S.ID = S.ID or 1
	S.STAGE = S.STAGE or 1
	S.STAGES = S.STAGES or { MAIN_MENU = 1, RUN = 2 }
	S.STAGE_OBJECTS = S.STAGE_OBJECTS or { {}, {} }
	S.STAGE_OBJECT_INTERRUPT = S.STAGE_OBJECT_INTERRUPT or false
	S.LIVE = S.LIVE or {
		NODE = {},
		TRANSFORM = {},
		SPRITE = {},
		POPUP = {},
		CARD = {},
		CARDAREA = {},
		ALERT = {},
	}
	S.TRANSFORMS = S.TRANSFORMS or {}
	S.ANIMATIONS = S.ANIMATIONS or {}
	S.ANIMATION_FPS = S.ANIMATION_FPS or 10
	S.FRAMES = S.FRAMES or { RENDER = 0, TRANSFORM = 0 }
	S.TIMERS = S.TIMERS or { REAL = 0, TOTAL = 0, UPTIME = 0, BACKGROUND = 0 }
	S.real_dt = S.real_dt or 0.016
	S.ROOM = S.ROOM or {
		T = { x = 0, y = 0, w = 20, h = 11 },
		jiggle = 0,
		alignment = { offset = { x = 0, y = 0 } },
	}
	S.ROOM_ATTACH = S.ROOM_ATTACH or {
		T = { x = 0, y = 0, w = 20, h = 11 },
		alignment = { offset = { x = 0, y = 0 } },
		align_to_major = function() end,
	}
	S.TEXTURE_ATLASES = S.TEXTURE_ATLASES or {}
	S.TEXTURE_ATLASES["ui_1"] = S.TEXTURE_ATLASES["ui_1"] or stub_atlas()
	S.TEXTURE_ATLASES["coin"] = S.TEXTURE_ATLASES["coin"] or stub_atlas()
	S.C = S.C or {}
	S.C.BACKGROUND = S.C.BACKGROUND or {
		C = { 0, 0, 0, 1 },
		L = { 0, 0, 0, 1 },
		D = { 0, 0, 0, 1 },
		contrast = 1,
	}
	S.C.GREEN = S.C.GREEN or { 0, 1, 0, 1 }
	S.SHADERS = S.SHADERS or {}

	require("jumbalaya-engine.util.colour")
	_G.ease_background_colour = _G.ease_background_colour or function() end
	_G.push_node_transform = _G.push_node_transform or function() end
	_G.track_hit_target = _G.track_hit_target or function() end
	_G.teardown_tree = _G.teardown_tree or function() end

	require("jumbalaya-engine.object")
	require("jumbalaya-engine.util.tables")
	require("jumbalaya-engine.util.tween")
	require("jumbalaya-engine.scene.node")
	require("jumbalaya-engine.scene.animated.init")
	require("jumbalaya-engine.graphics.sprite")
	require("jumbalaya-engine.graphics.sprite_animator")
	require("jumbalaya-engine.interaction.router")
end

function M.ensure_card_class()
	M.ensure_engine_globals()
	require("word_game.model.cards.card")
	require("word_game.ui.cards.bind").install()
end

function M.install_presentation(overrides)
	_G.WORD_GAME = _G.WORD_GAME or {}
	_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
	_G.WORD_GAME_UI.ScoreBanner = _G.WORD_GAME_UI.ScoreBanner or {
		reset = function() end,
		state = function() return { to_go_label = "SCORE", target = 0, remaining = 0 } end,
		reset_jumble_score = function() end,
	}
	if overrides then
		for key, value in pairs(overrides) do
			_G.WORD_GAME_UI[key] = value
		end
	end
	require("word_game.ui.presentation.install").install(_G.WORD_GAME_UI, _G.WORD_GAME)
end

function M.setup()
	M.ensure_engine_globals()
	local S = shell_game()
	S.C = S.C or {
		CLEAR = { 0, 0, 0, 0 },
		RED = { 1, 0, 0, 1 },
		GREEN = { 0, 1, 0, 1 },
		GOLD = { 1, 0.8, 0, 1 },
		WHITE = { 1, 1, 1, 1 },
		UI = { TRANSPARENT_DARK = { 0, 0, 0, 0.5 }, TEXT_LIGHT = { 1, 1, 1, 1 } },
		DYN_UI = { BOSS_MAIN = { 1, 1, 1, 1 }, BOSS_DARK = { 0, 0, 0, 1 }, MAIN = { 0.22, 0.32, 0.35, 1 } },
	}
	S.UI = S.UI or { ROOT = 1, ROW = 2, COL = 3, TEXT = 4, OBJECT = 5, BOX = 6 }
	S.TILE_W = S.TILE_W or 20
	S.TILE_H = S.TILE_H or 11
	S.CARD_W = S.CARD_W or 1
	S.CARD_H = S.CARD_H or 1.4
	S.HAND_CARD_SPACING = S.HAND_CARD_SPACING or 0.78
	S.TABLE_HAND_SIZE = S.TABLE_HAND_SIZE or 7
	S.TABLE_BOARD_SIDEBAR_WIDTH = S.TABLE_BOARD_SIDEBAR_WIDTH or 3.0
	S.STATES = S.STATES or { TABLE_BOARD = 1, MENU = 2 }
	S.STAGES = S.STAGES or { RUN = 1, MAIN_MENU = 2 }
	S.DEFINITIONS = S.DEFINITIONS or {}
	S.TIMERS = S.TIMERS or { REAL = 0, TOTAL = 0, UPTIME = 0, BACKGROUND = 0 }
	S.ROOM = S.ROOM or { T = { x = 0, y = 0, w = 20, h = 11 }, jiggle = 0 }
	S.LETTERS = S.LETTERS or {
		faces = { letter_base = { key = "letter_base" }, empty = {} },
		centers = { letter_base = { key = "letter_base" } },
		center_pools = {},
		locked = {},
	}
	S.letter_inventory = S.letter_inventory or {}
	S.ROOM_ATTACH = S.ROOM_ATTACH or {
		T = { x = 0, y = 0, w = 20, h = 11 },
		alignment = { offset = { x = 0, y = 0 } },
		align_to_major = function() end,
	}
	S.POINTER = S.POINTER or {
		T = { x = 0, y = 0, w = 1, h = 1 },
		VT = { x = 0, y = 0, w = 1, h = 1 },
		states = { hover = {}, click = {}, collide = {}, drag = {} },
	}
	S.INPUT = S.INPUT or {
		locks = {},
		hover_state = { T = { x = 0, y = 0 }, time = 0 },
		cursor_position = { x = 0, y = 0 },
		shift_context_layer = function() end,
		focus_cursor_stack = {},
		focus_cursor_stack_level = 1,
		snap_to = function() end,
	}
	_G.pick_random = _G.pick_random or function(t)
		if not t then return nil end
		if #t > 0 then return t[1] end
		for _, v in pairs(t) do return v end
	end
	_G.boot_stage = _G.boot_stage or function() end
	_G.get_table_felt_rect = _G.get_table_felt_rect or function()
		return { x = 0.8, y = 2.0, w = 15.4, h = 8.0 }
	end

	love.audio = love.audio or {
		newSource = function(_path, _type)
			return {
				setVolume = function() end,
				setPitch = function() end,
				setLooping = function() end,
				isPlaying = function() return true end,
				play = function() end,
				stop = function() end,
				pause = function() end,
				release = function() end,
			}
		end,
		play = function() end,
		stop = function() end,
		pause = function() end,
	}

	local noop = function() end
	love.graphics = love.graphics or {}
	love.graphics.push = noop
	love.graphics.pop = noop
	love.graphics.scale = noop
	love.graphics.translate = noop
	love.graphics.rotate = noop
	love.graphics.clear = noop
	love.graphics.setColor = noop
	love.graphics.getColor = function() return 1, 1, 1, 1 end
	love.graphics.setShader = noop
	love.graphics.getShader = function() return nil end
	love.graphics.newText = function(_font, text)
		return {
			getWidth = function() return #(text or "") * 10 end,
			getHeight = function() return 20 end,
			set = noop,
			draw = noop,
		}
	end
	love.graphics.setBlendMode = noop
	love.graphics.getBlendMode = function() return "alpha", "alphamultiply" end
	love.graphics.setCanvas = noop
	love.graphics.getCanvas = function() return nil end
	love.graphics.newCanvas = function(w, h)
		return {
			setFilter = noop,
			getDimensions = function() return w or 20, h or 11 end,
			getWidth = function() return w or 20 end,
			getHeight = function() return h or 11 end,
			getPixelHeight = function() return h or 11 end,
			getPixelWidth = function() return w or 20 end,
		}
	end
	love.graphics.draw = noop
	love.graphics.rectangle = noop
	love.graphics.circle = noop
	love.graphics.arc = noop
	love.graphics.line = noop
	love.graphics.polygon = noop
	love.graphics.print = noop
	love.graphics.printf = noop
	love.graphics.newQuad = function(x, y, w, h) return { x = x, y = y, w = w, h = h } end
	love.graphics.newFont = function()
		return {
			getWidth = function(_, str) return #(str or "") * 10 end,
			getHeight = function() return 20 end,
			setFilter = noop,
		}
	end
	love.graphics.setFont = noop
	love.graphics.getFont = function() return love.graphics.newFont() end
	love.graphics.isActive = function() return true end
	love.graphics.getPixelDimensions = love.graphics.getPixelDimensions or function()
		return 1280, 720
	end
	love.graphics.getDimensions = love.graphics.getDimensions or function()
		return 1280, 720
	end
	love.graphics.setDefaultFilter = love.graphics.setDefaultFilter or function() end
	love.graphics.setLineStyle = love.graphics.setLineStyle or function() end
	love.graphics.setLineWidth = love.graphics.setLineWidth or function() end

	_G.WORD_GAME = _G.WORD_GAME or {}
	_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
	_G.Tween = _G.Tween or function(def) return def end
	_G.read_save_payload = _G.read_save_payload or function() return nil end
	_G.unpack_source = _G.unpack_source or function(_str) return {} end
	S.TIMELINE = Scheduler()
	_G.play_sfx = _G.play_sfx or function() end
	_G.spawn_attention = _G.spawn_attention or function() end
	_G.attention = _G.attention or function() end
	_G.Card = _G.Card or function(x, y, w, h, front, center, _params)
		return {
			T = { x = x or 0, y = y or 0, w = w or 1, h = h or 1.4 },
			VT = { x = x or 0, y = y or 0, w = w or 1, h = h or 1.4 },
			ability = {},
			config = { center = center, card = front },
			states = { hover = {}, click = {}, collide = {}, drag = {} },
			set_sprites = function() end,
			pulse = function() end,
			remove = function() end,
		}
	end

	package.preload["dictionary.words_set"] = package.preload["dictionary.words_set"] or function()
		return {
			CAT = true, CAR = true, ACE = true, TEA = true, EAT = true,
			ACT = true, ART = true, ARE = true, EAR = true, ERA = true,
		}
	end

	local ok, dict = pcall(require, "dictionary")
	if ok then
		_G.Dictionary = dict
		dict.load()
	end

	local ok_jumble, jumble = pcall(require, "word_game.model.jumble")
	if ok_jumble then
		_G.WORD_GAME.Jumble = jumble
	end

	local ok_sb, score_banner = pcall(require, "word_game.ui.score_banner")
	if ok_sb then
		_G.WORD_GAME_UI.ScoreBanner = score_banner
	end

	local ok_tt, timeline_timer = pcall(require, "word_game.ui.perks.timeline_timer")
	if ok_tt then
		_G.WORD_GAME_UI.TimelineTimer = timeline_timer
	end

	local ok_sl, stage_label = pcall(require, "word_game.ui.score_banner.stage_label")
	if ok_sl then
		_G.WORD_GAME_UI.StageLabel = stage_label
	end

	local ok_flow, flow = pcall(require, "word_game.model.jumble_play")
	if ok_flow then
		_G.WORD_GAME.Play = flow
	end

	local ok_geo, jg = pcall(require, "word_game.board.jumble.geometry")
	if ok_geo then
		S.pattern_row = S.pattern_row or {}
		S.pattern_row.jumble_geometry = jg
		if not S.pattern_row.relayout then
			S.pattern_row.relayout = function() end
		end
	end
end

function M.install_hand_clear(play_module)
	play_module = play_module or require("word_game.model.jumble_play")
	require("word_game.ui.play_effects.hand_clear").install(play_module)
	_G.WORD_GAME = _G.WORD_GAME or {}
	_G.WORD_GAME.Play = play_module
	return play_module
end

function M.reset_game()
	M.setup()
	require("word_game.model.jumble.bonus_stack").clear()
	local ok_fly, card_fly_off = pcall(require, "word_game.ui.play_effects.card_fly_off")
	if ok_fly and card_fly_off.reset then
		card_fly_off.reset()
	end
	if _G.WORD_GAME then
		_G.WORD_GAME.Deck = require("word_game.model.cards.deck")
		_G.WORD_GAME_UI.TradeUI = nil
		_G.WORD_GAME_UI.TokenReward = nil
		_G.WORD_GAME_UI.CardFlyOff = nil
	end
	local S = shell_game()
	if S.SIDEBAR_HUD and S.SIDEBAR_HUD.remove then
		pcall(function() S.SIDEBAR_HUD:remove() end)
	end
	S.SIDEBAR_HUD = nil
	local jg = S.pattern_row and S.pattern_row.jumble_geometry
	S.pattern_row = {
		relayout = function() end,
		jumble_geometry = jg,
	}
	local initial = {
		points = 0,
		seed_streams = { seed = "TEST", hashed_seed = 0 },
		word_round = {
			set = 1,
			hand_index = 1,
			played_words = {},
		},
	}
	S.STATE = nil
	S.ARGS = S.ARGS or {}
	local ok_stage, stage_button = pcall(require, "word_game.ui.sidebar.stage_button")
	if ok_stage and stage_button.reset then
		stage_button.reset()
		stage_button.bind_button_proxy(nil, nil)
	end
	local ok_views, views_install = pcall(require, "word_game.ui.views.install")
	if ok_views and views_install.reset then
		views_install.reset()
	end
	M.publish_game(initial)
end

function M.publish_game(game_table)
	if not game_table then return end
	_G.WORD_GAME = require("word_game")
	local store_ops = require("word_game.model.store_ops")
	store_ops.ensure_test_binding()
	local store = store_ops.store()
	if store then
		store_ops.bind_run(store, game_table)
		store_ops.patch(store, {
			piles = { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} },
		})
	end
	local shell_bind = package.loaded["app.bootstrap.shell_bind"]
	if shell_bind and shell_bind.install then
		shell_bind.install()
	elseif pcall(require, "app.bootstrap.shell_bind") then
		require("app.bootstrap.shell_bind").install()
	end
end

function M.game_state()
	return require("word_game.model.game_access").get()
end

function M.patch_game(fields)
	return require("word_game.model.game_access").patch(fields)
end

function M.mutate_game(fn)
	return require("word_game.model.game_access").mutate(fn)
end

function M.clear_store_piles()
	local store = require("word_game.model.store_ops").store()
	if store then
		require("word_game.model.store_ops").patch(store, {
			piles = { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} },
		})
	end
end

function M.teardown_boot_pollution()
	M.reset_game()
end

return M
