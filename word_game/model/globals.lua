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
        self.SETTINGS.GRAPHICS.crt = 0
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

    self.TILESIZE = 20
    self.TILESCALE = 3.65
    self.TILE_W = 20
    self.TILE_H = 11.5
    self.CANVAS_SCALE = 1
    self.DRAW_HASH_BUFF = 2
    self.CARD_W = 2.4*35/41
    self.CARD_H = 2.4*47/41
    self.HIGHLIGHT_H = 0.2*self.CARD_H
    self.COLLISION_BUFFER = 0.05
    self.HAND_CARD_SPACING = 0.78   -- gap between card centres as a fraction of card width (lower = tighter fan)
    self.SHOW_SIDE_PANEL = false    -- HUD overlay (not split-screen panel)
    self.TABLE_HAND_SIZE = 7        -- random cards dealt on the board
    self.TABLE_BOARD_SIDEBAR_WIDTH = 3.0  -- fixed width for the vault side panel

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

    self.MIN_CLICK_DIST = 0.9
    self.MIN_HOVER_TIME = 0.1
    self.DEBUG = false
    self.ANIMATION_FPS = 10
    self.VIBRATION = 0
    self.CHALLENGE_WINS = 5
    self.CHALLENGES = {}

    self.C = {
        MULTIPLIER = colour_from_hex('FE5F55'),
        POINTS = colour_from_hex("009dff"),
        MONEY = colour_from_hex('f3b958'),
        XMULT = colour_from_hex('FE5F55'),
        FILTER = colour_from_hex('ff9a00'),
        BLUE = colour_from_hex("009dff"),
        RED = colour_from_hex('FE5F55'),
        GREEN = colour_from_hex("4BC292"),
        PALE_GREEN = colour_from_hex("56a887"),
        ORANGE = colour_from_hex("fda200"),
        IMPORTANT = colour_from_hex("ff9a00"),
        GOLD = colour_from_hex('eac058'),
        YELLOW = {1,1,0,1},
        CLEAR = {0, 0, 0, 0}, 
        WHITE = {1,1,1,1},
        PURPLE = colour_from_hex('8867a5'),
        BLACK = colour_from_hex("374244"),--4f6367"),
        L_BLACK = colour_from_hex("4f6367"),
        GREY = colour_from_hex("5f7377"),
        CHANCE = colour_from_hex("4BC292"),
        MUTED_GREY = colour_from_hex('bfc7d5'),
        BOOSTER = colour_from_hex("646eb7"),
        FINISH = {1,1,1,1},
        DARK_FINISH = {0,0,0,1},
        
        DYN_UI = {
            MAIN = colour_from_hex('424e54'),
            DARK = colour_from_hex('374244'),
            BOSS_MAIN = colour_from_hex('374244'),
            BOSS_DARK = colour_from_hex('374244'),
        },
        UI = {
            TEXT_LIGHT = {1,1,1,1},
            TEXT_DARK = colour_from_hex("4F6367"),
            TEXT_INACTIVE = colour_from_hex("88888899"),
            BACKGROUND_WHITE = {1,1,1,1},
            BACKGROUND_DARK = colour_from_hex("7A9E9F"),
            BACKGROUND_INACTIVE = colour_from_hex("666666FF"),
            OUTLINE_LIGHT = colour_from_hex("D8D8D8"),
            TRANSPARENT_LIGHT = colour_from_hex("eeeeee22"),
            TRANSPARENT_DARK = colour_from_hex("22222222"),
            HOVER = colour_from_hex('00000055'),
            BUTTON = colour_from_hex('1958C8'),
            BUTTON_HOVER = colour_from_hex('286FE0'),
            BUTTON_OUTLINE = colour_from_hex('1958C8'),
            BUTTON_TEXT = colour_from_hex('F4F8FF'),
        },
        SET = {
            Default = colour_from_hex("cdd9dc"),
            Enhanced = colour_from_hex("cdd9dc"),
            Companion = colour_from_hex('424e54'),
            Charm = colour_from_hex('424e54'),
            Orbit = colour_from_hex("424e54"),
            Phantom = colour_from_hex('424e54'),
            Perk = colour_from_hex("424e54"),
        }, 
        SECONDARY_SET = {
            Default = colour_from_hex("9bb6bdFF"),
            Enhanced = colour_from_hex("8389DDFF"),
            Companion = colour_from_hex('708b91'),
            Charm = colour_from_hex('a782d1'),
            Orbit = colour_from_hex('13afce'),
            Phantom = colour_from_hex('4584fa'),
            Perk = colour_from_hex("fd682b"),
            Finish = colour_from_hex("4ca893"),
        }, 
        RARITY = {
            colour_from_hex('009dff'),--colour_from_hex("708b91"),
            colour_from_hex("4BC292"),
            colour_from_hex('fe5f55'),
            colour_from_hex("b26cbb")
        },

        BACKGROUND = {
            L = {1,1,0,1},
            D = {0,1,1,1},
            C = colour_from_hex("374244"),
            contrast = 1
        }
    }
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
