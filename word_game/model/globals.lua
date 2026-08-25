--[[
	Initializes the shared game state used by the Jumbalaya runtime.
	global state container `G` (instantiated at the bottom of this file as
	`G = Game()`).

	Everything the game reads/writes at runtime - feature flags, settings,
	render scale, colours, instance registries (`G.LIVE.*`), state machine enums,
	table layout constants, etc. - lives on `G`. This function is called once
	during boot (`G:launch()` in `app/startup.lua`) to set all of that up.

]]

local RuntimeOptions = require("word_game.config.runtime_options")
local Palette = require("word_game.config.palette")
local Dimensions = require("word_game.config.dimensions")

VERSION = '1.0.0i'
VERSION = VERSION..'-FULL'

--- Populates every field on `G` (self here is the `Game` instance). Called
--- once at boot; some settings-menu / save-load code paths also re-invoke
--- parts of this indirectly by resetting `G.SETTINGS`, so avoid assuming
--- this only ever runs a single time in the process lifetime.
function Game:define_constants()
    self.VERSION = VERSION

    for name, value in pairs(RuntimeOptions.flags) do
        self["F_" .. name] = value
    end
    -- Runtime feature switches are supplied by the configuration package.
    self.SEED = os.time()
    self.TIMERS = {
        TOTAL=0,
        REAL = 0,
        UPTIME = 0,
        BACKGROUND = 0
    }
    self.FRAMES = {
        RENDER = 0,
        TRANSFORM = 0
    }
    self.smoothing = {xy = 0, scale = 0, r = 0}
    self.SETTINGS = RuntimeOptions.settings()

    local os_name = love.system.getOS()
    if os_name == 'iOS' or os_name == 'Android' then
        -- Mobile: lower memory use and avoid audio thread issues on LÖVE iOS.
        self.F_SOUND_THREAD = false
        self.F_VERBOSE = false
        self.SETTINGS.GRAPHICS.texture_scaling = 1
        self.SETTINGS.WINDOW.screenmode = 'Borderless'
        self.SETTINGS.WINDOW.selected_display = 1
    elseif os_name == 'Windows' then
        self.F_DISCORD = true
        self.F_CRASH_REPORTS = true
    elseif os_name == 'OS X' then
        self.F_DISCORD = true
        self.F_CRASH_REPORTS = false
    end

    self.METRICS = {}

    self.PROFILES = {
        {},
        {},
        {},
    }

    -- Render/layout constants come from the typed dimensions module.
    self.TILESIZE = Dimensions.TILESIZE
    self.TILESCALE = Dimensions.TILESCALE
    self.CANVAS_SCALE = Dimensions.CANVAS_SCALE
    self.TILE_W = Dimensions.TILE_W
    self.TILE_H = Dimensions.TILE_H
    self.DRAW_HASH_BUFF = Dimensions.DRAW_HASH_BUFF
    self.COLLISION_BUFFER = Dimensions.COLLISION_BUFFER
    self.CARD_W = Dimensions.CARD_W
    self.CARD_H = Dimensions.CARD_H
    self.HIGHLIGHT_H = Dimensions.HIGHLIGHT_H
    self.HAND_CARD_SPACING = Dimensions.layout.HAND_CARD_SPACING
    self.SHOW_SIDE_PANEL = Dimensions.layout.SHOW_SIDE_PANEL
    self.TABLE_HAND_SIZE = Dimensions.layout.TABLE_HAND_SIZE
    self.TABLE_BOARD_SIDEBAR_WIDTH = Dimensions.layout.TABLE_BOARD_SIDEBAR_WIDTH

    self.PITCH_MOD = 1

    -- Numeric values are stable save-format identifiers: run saves persist
    -- `G.STATE` and restore it verbatim (see Game:start_run), so existing
    -- numbers must not be renumbered or old saves break.
    self.STATES = {
        GAME_OVER = 4,
        MENU = 11,
        SPLASH = 13, -- reserved for sound initialization
        TABLE_BOARD = 20,
    }

    self.STAGES = {
        MAIN_MENU = 1,
        RUN = 2,
    }
    self.STAGE_OBJECTS = {
        {},{}
    }
    self.STAGE = self.STAGES.MAIN_MENU
    self.STATE = self.STATES.SPLASH
    self.STATE_COMPLETE = false

    self.ARGS = {}
    self.FUNCS = {}
    self.UIDEF = {}
    self.LIVE = {
        NODE = {},
        TRANSFORM = {},
        SPRITE = {},
        UIBOX = {},
        POPUP = {},
        CARD = {},
        CARDAREA = {},
        ALERT = {}
    }
    self.ANIM_SHEETS = {}
    self.TEXTURE_ATLASES = {}
    self.TRANSFORMS = {}
    self.ANIMATIONS = {}
    self.HIT_ORDER = {}

    self.MIN_CLICK_DIST = Dimensions.layout.MIN_CLICK_DIST
    self.MIN_HOVER_TIME = Dimensions.layout.MIN_HOVER_TIME
    self.DEBUG = false
    self.ANIMATION_FPS = Dimensions.layout.ANIMATION_FPS
    self.VIBRATION = 0
    self.CHALLENGE_WINS = 5
    self.CHALLENGES = {}

    -- The colour system lives in the palette module; this only assembles it.
    self.C = Palette.build(colour_from_hex)
    self.C.UI_POINTS = deep_clone(self.C.BLUE)
    self.C.UI_MULTIPLIER = deep_clone(self.C.RED)
    self.UI = {
        TEXT = 1,
        BOX = 2,      -- rounded box
        COLUMN = 3,
        ROW = 4,
        OBJECT = 5,   -- wraps a live SceneNode
        ROOT = 7,
        SLIDER = 8,
        INPUT = 9,    -- text input box
        padding = 0,  -- default padding
    }
    self.button_mapping = {}
    self.keybind_mapping = {{
        a = 'dpleft',
        d = 'dpright',
        w = 'dpup',
        s = 'dpdown',
        x = 'x',
        c = 'y',
        space = 'a',
        shift = 'b',
        esc = 'start',
        q = 'triggerleft',
        e = 'triggerright',
    }}
end

-- The one and only Game instance. Everything else in the codebase reaches
-- game state through this global (`G.STATE`, `G.C`, `G.LIVE.CARD`, etc.).
---@type Game
G = Game()
