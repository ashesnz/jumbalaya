--[[
	word_game/config/dimensions.lua - typed render/layout constants.

	Derivations, not magic numbers:
	  - `TILESIZE` is the world-unit root; everything else scales from it.
	  - One tile occupies `CANVAS_TILE_PX` on-screen pixels at zoom 1, giving
	    TILESCALE = 73/20.
	  - Card dimensions derive from the letter-atlas cell (71x95 px per face in
	    resources/textures/{1,2}x/JumbalayaLetters.png) times a single
	    art-pixel-to-world-unit factor tuned so a full vault row fits its
	    sidebar with gutters.
]]

---@class DimensionsSpec
local M = {}

-- Render root ----------------------------------------------------------------
M.TILESIZE = 20            -- world units per tile
M.CANVAS_TILE_PX = 73      -- screen pixels per tile at zoom 1
M.TILESCALE = M.CANVAS_TILE_PX / M.TILESIZE
M.CANVAS_SCALE = 1         -- global canvas supersampling

-- Tile grid -------------------------------------------------------------------
M.TILE_W = M.TILESIZE                       -- board tile width (1 tile)
M.TILE_H = M.TILESIZE * 0.575               -- letter-tile row height (11.5)

-- Cards -----------------------------------------------------------------------
M.CARD_ART_W = 71          -- deck-atlas face width, px at 1x
M.CARD_ART_H = 95          -- deck-atlas face height, px at 1x
M.ART_TO_WORLD = 0.0289    -- world units per atlas pixel
M.CARD_W = M.ART_TO_WORLD * M.CARD_ART_W   -- ~= 2.05 world units
M.CARD_H = M.ART_TO_WORLD * M.CARD_ART_H   -- ~= 2.75 world units
M.HIGHLIGHT_H = 0.2 * M.CARD_H             -- selection lift height

-- Collision / culling -----------------------------------------------------------
M.DRAW_HASH_BUFF = 2
M.COLLISION_BUFFER = 0.05

-- Board layout ------------------------------------------------------------------
M.layout = {
	HAND_CARD_SPACING = 0.78,       -- gap between card centres as a fraction of card width
	TABLE_HAND_SIZE = 7,            -- random cards dealt onto the board
	TABLE_BOARD_SIDEBAR_WIDTH = 3.0, -- vault side-panel width
	SHOW_SIDE_PANEL = false,        -- HUD overlay (not split-screen panel)
	MIN_CLICK_DIST = 0.9,
	MIN_HOVER_TIME = 0.1,
	ANIMATION_FPS = 10,
}

return M
