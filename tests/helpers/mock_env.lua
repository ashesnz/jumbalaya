--[[ tests/helpers/mock_env.lua
     Provides a standard test environment and global mocks for unit tests.
]]

local M = {}

local function stub_atlas()
	return {
		px = 4,
		py = 4,
		image = { getDimensions = function() return 4, 4 end },
	}
end

--- Load real engine classes (AnimNode, Sprite, etc.) so tests never use stub moveables.
function M.ensure_engine_globals()
	package.path = "./?.lua;./?/init.lua;" .. package.path

	_G.G = _G.G or {}
	G.SETTINGS = G.SETTINGS or {
		paused = false,
		GRAPHICS = { shadows = "Off", texture_scaling = 1 },
	}
	G.ID = G.ID or 1
	G.STAGE = G.STAGE or 1
	G.STAGES = G.STAGES or { MAIN_MENU = 1, RUN = 2 }
	G.STAGE_OBJECTS = G.STAGE_OBJECTS or { {}, {} }
	G.STAGE_OBJECT_INTERRUPT = G.STAGE_OBJECT_INTERRUPT or false
	G.LIVE = G.LIVE or {
		NODE = {},
		TRANSFORM = {},
		SPRITE = {},
		UIBOX = {},
		POPUP = {},
		CARD = {},
		CARDAREA = {},
		ALERT = {},
	}
	G.TRANSFORMS = G.TRANSFORMS or {}
	G.ANIMATIONS = G.ANIMATIONS or {}
	G.ANIMATION_FPS = G.ANIMATION_FPS or 10
	G.FRAMES = G.FRAMES or { RENDER = 0, TRANSFORM = 0 }
	G.TIMERS = G.TIMERS or { REAL = 0, TOTAL = 0, UPTIME = 0, BACKGROUND = 0 }
	G.real_dt = G.real_dt or 0.016
	G.ROOM = G.ROOM or {
		T = { x = 0, y = 0, w = 20, h = 11 },
		jiggle = 0,
		alignment = { offset = { x = 0, y = 0 } },
	}
	G.ROOM_ATTACH = G.ROOM_ATTACH or {
		T = { x = 0, y = 0, w = 20, h = 11 },
		alignment = { offset = { x = 0, y = 0 } },
		align_to_major = function() end,
	}
	G.TEXTURE_ATLASES = G.TEXTURE_ATLASES or {}
	G.TEXTURE_ATLASES["ui_1"] = G.TEXTURE_ATLASES["ui_1"] or stub_atlas()
	G.TEXTURE_ATLASES["coin"] = G.TEXTURE_ATLASES["coin"] or stub_atlas()
	G.C = G.C or {}
	G.C.BACKGROUND = G.C.BACKGROUND or {
		C = { 0, 0, 0, 1 },
		L = { 0, 0, 0, 1 },
		D = { 0, 0, 0, 1 },
		contrast = 1,
	}
	G.C.GREEN = G.C.GREEN or { 0, 1, 0, 1 }
	G.SHADERS = G.SHADERS or {}

	require("app.core.util.colour") -- installs colour_from_hex and friends
	_G.ease_background_colour = _G.ease_background_colour or function() end
	_G.push_node_transform = _G.push_node_transform or function() end
	_G.track_hit_target = _G.track_hit_target or function() end
	_G.teardown_tree = _G.teardown_tree or function() end

	require("app.core.object")
	require("app.core.util.tables")
	require("app.core.util.tween")
	require("app.core.scene.node")
	require("app.core.scene.animated.init")
	require("app.core.graphics.sprite")
	require("app.core.graphics.sprite_animator")
	require("app.core.input.router")
end

function M.setup()
	M.ensure_engine_globals()
	G.C = G.C or {
		CLEAR = { 0, 0, 0, 0 },
		RED = { 1, 0, 0, 1 },
		GREEN = { 0, 1, 0, 1 },
		GOLD = { 1, 0.8, 0, 1 },
		WHITE = { 1, 1, 1, 1 },
		UI = { TRANSPARENT_DARK = { 0, 0, 0, 0.5 } },
		DYN_UI = { BOSS_MAIN = { 1, 1, 1, 1 }, BOSS_DARK = { 0, 0, 0, 1 }, MAIN = { 1, 1, 1, 1 } },
	}
	G.UI = G.UI or { ROOT = 1, R = 2, C = 3, T = 4, O = 5 }
	G.TILE_W = G.TILE_W or 20
	G.TILE_H = G.TILE_H or 11
	G.CARD_W = G.CARD_W or 1
	G.CARD_H = G.CARD_H or 1.4
	G.HAND_CARD_SPACING = G.HAND_CARD_SPACING or 0.78
	G.TABLE_HAND_SIZE = G.TABLE_HAND_SIZE or 7
	G.TABLE_BOARD_SIDEBAR_WIDTH = G.TABLE_BOARD_SIDEBAR_WIDTH or 3.0
	G.STATES = G.STATES or { TABLE_BOARD = 1, MENU = 2 }
	G.STAGES = G.STAGES or { RUN = 1, MAIN_MENU = 2 }
	G.DEFINITIONS = G.DEFINITIONS or {}
	G.FUNCS = G.FUNCS or {}
	G.GAME = G.GAME or {}
	G.TIMERS = G.TIMERS or { REAL = 0, TOTAL = 0, UPTIME = 0, BACKGROUND = 0 }
	G.ROOM = G.ROOM or { T = { x = 0, y = 0, w = 20, h = 11 }, jiggle = 0 }
	G.P_CENTERS = G.P_CENTERS or { letter_base = { key = "letter_base" } }
	G.P_CARDS = G.P_CARDS or { letter_base = { key = "letter_base" } }
	G.ROOM_ATTACH = G.ROOM_ATTACH or {
		T = { x = 0, y = 0, w = 20, h = 11 },
		alignment = { offset = { x = 0, y = 0 } },
		align_to_major = function() end,
	}
	G.POINTER = G.POINTER or {
		T = { x = 0, y = 0, w = 1, h = 1 },
		VT = { x = 0, y = 0, w = 1, h = 1 },
		states = { hover = {}, click = {}, collide = {}, drag = {} },
	}
	G.INPUT = G.INPUT or {
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
		newSource = function(path, type)
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

	love.graphics = love.graphics or {}
	love.graphics.push = love.graphics.push or function() end
	love.graphics.pop = love.graphics.pop or function() end
	love.graphics.scale = love.graphics.scale or function() end
	love.graphics.translate = love.graphics.translate or function() end
	love.graphics.rotate = love.graphics.rotate or function() end
	love.graphics.clear = love.graphics.clear or function() end
	love.graphics.setColor = love.graphics.setColor or function() end
	love.graphics.getColor = love.graphics.getColor or function() return 1, 1, 1, 1 end
	love.graphics.setShader = love.graphics.setShader or function() end
	love.graphics.getShader = love.graphics.getShader or function() return nil end
	love.graphics.setBlendMode = love.graphics.setBlendMode or function() end
	love.graphics.getBlendMode = love.graphics.getBlendMode or function()
		return "alpha", "alphamultiply"
	end
	love.graphics.setCanvas = love.graphics.setCanvas or function() end
	love.graphics.getCanvas = love.graphics.getCanvas or function() return nil end
	love.graphics.newCanvas = love.graphics.newCanvas or function(w, h)
		return {
			setFilter = function() end,
			getDimensions = function() return w or 20, h or 11 end,
			getWidth = function() return w or 20 end,
			getHeight = function() return h or 11 end,
			getPixelHeight = function() return h or 11 end,
			getPixelWidth = function() return w or 20 end,
		}
	end
	love.graphics.draw = love.graphics.draw or function() end
	love.graphics.rectangle = love.graphics.rectangle or function() end
	love.graphics.circle = love.graphics.circle or function() end
	love.graphics.arc = love.graphics.arc or function() end
	love.graphics.line = love.graphics.line or function() end
	love.graphics.polygon = love.graphics.polygon or function() end
	love.graphics.print = love.graphics.print or function() end
	love.graphics.printf = love.graphics.printf or function() end
	love.graphics.newQuad = love.graphics.newQuad or function(x, y, w, h, sw, sh) return { x = x, y = y, w = w, h = h } end
	love.graphics.newFont = love.graphics.newFont or function()
		return {
			getWidth = function(_, str) return #(str or "") * 10 end,
			getHeight = function() return 20 end,
			setFilter = function() end,
		}
	end
	love.graphics.setFont = love.graphics.setFont or function() end
	love.graphics.getFont = love.graphics.getFont or function() return love.graphics.newFont() end
	love.graphics.isActive = love.graphics.isActive or function() return true end
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
	_G.Tween = _G.Tween or function(def) return def end
	_G.read_save_payload = _G.read_save_payload or function() return nil end
	_G.unpack_source = _G.unpack_source or function(str) return {} end
	G.TIMELINE = Scheduler()
	_G.play_sfx = _G.play_sfx or function() end
	_G.spawn_attention = _G.spawn_attention or function() end
	_G.attention = _G.attention or function() end
	_G.Card = _G.Card or function(x, y, w, h, front, center, params)
		return {
			T = { x = x or 0, y = y or 0, w = w or 1, h = h or 1.4 },
			VT = { x = x or 0, y = y or 0, w = w or 1, h = h or 1.4 },
			ability = {},
			config = { center = center, card = front },
			states = { hover = {}, click = {}, collide = {}, drag = {} },
			set_sprites = function(self) end,
			pulse = function(self) end,
			remove = function(self) end,
		}
	end

	-- Ensure root package paths are set
	package.path = "./?.lua;./?/init.lua;" .. package.path

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
		_G.WORD_GAME.ScoreBanner = score_banner
	end

	local ok_tt, timeline_timer = pcall(require, "word_game.ui.timeline_timer")
	if ok_tt then
		_G.WORD_GAME.TimelineTimer = timeline_timer
	end

	local ok_sl, stage_label = pcall(require, "word_game.ui.stage_label")
	if ok_sl then
		_G.WORD_GAME.StageLabel = stage_label
	end

	local ok_flow, flow = pcall(require, "word_game.model.play")
	if ok_flow then
		_G.WORD_GAME.Play = flow
	end

	local ok_geo, jg = pcall(require, "word_game.board.jumble_geometry")
	if ok_geo then
		G.placement_table = G.placement_table or {}
		G.placement_table.jumble_geometry = jg
		if not G.placement_table.relayout then
			G.placement_table.relayout = function() end
		end
	end
end

function M.reset_game()
	M.setup()
	if G.VAULT_HUD and G.VAULT_HUD.remove then
		pcall(function() G.VAULT_HUD:remove() end)
	end
	G.VAULT_HUD = nil
	G.word_sidebar_uibox = nil
	local jg = G.placement_table and G.placement_table.jumble_geometry
	G.placement_table = {
		relayout = function() end,
		jumble_geometry = jg,
	}
	G.GAME = {
		points = 0,
		seed_streams = { seed = "TEST", hashed_seed = 0 },
		word_round = {
			set = 1,
			hand_index = 1,
			plays_left = 6,
			played_words = {},
		},
	}
end

function M.teardown_boot_pollution()
	M.reset_game()
end

return M
