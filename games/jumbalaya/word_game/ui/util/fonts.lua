--[[ word_game/ui/util/fonts.lua - Cached game fonts from resources/fonts ]]

local GameFiles = require("app.platform.game_files")

local M = {}

M.OUTFIT_BOLD = "resources/fonts/Outfit-Bold.ttf"
M.SNIGLET_EXTRA_BOLD = "resources/fonts/Sniglet-ExtraBold.ttf"

local cache = {}

function M.load(rel_path, px)
	px = math.max(1, math.floor(px or 12))
	local key = rel_path .. "@" .. px
	local cached = cache[key]
	if cached then
		return cached
	end
	local font = GameFiles.load_font(rel_path, px)
	if not font and love and love.graphics and love.graphics.newFont then
		font = love.graphics.newFont(px)
	end
	if font and font.setFilter then
		font:setFilter("linear", "linear")
	end
	cache[key] = font
	return font
end

function M.outfit(px)
	return M.load(M.OUTFIT_BOLD, px)
end

function M.sniglet(px)
	return M.load(M.SNIGLET_EXTRA_BOLD, px) or M.outfit(px)
end

--- FlowText / LANG-compatible font table (Outfit-Bold at UI scale).
function M.flow_text_spec()
	local game = require("word_game.ui.util.game_runtime").game
	local g = game and game()
	local ts = (g and g.TILESIZE) or 20
	local render_scale = ts * 7
	return {
		FONT = M.outfit(render_scale),
		TEXT_OFFSET = { x = 0, y = -28 },
		FONTSCALE = 0.12,
		TEXT_HEIGHT_SCALE = 0.7,
		squish = 1,
		DESCSCALE = 1,
	}
end

function M.resolve_flow_text_font()
	local game = require("word_game.ui.util.game_runtime").game
	local g = game and game()
	local lang_font = g and g.LANG and g.LANG.font
	if lang_font and lang_font.FONT then
		return lang_font
	end
	return M.flow_text_spec()
end

return M
