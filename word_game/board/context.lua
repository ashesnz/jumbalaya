--[[
	word_game.board/context.lua - Engine facade passed into placement subsystems.

	Keeps placement modules from scattering direct `G` reads and documents the
	contract between the word_game.board package and the Game object.
]]

local config = require "word_game.board.config"

--- @class PlacementContext
--- @field game Game
local PlacementContext = {}
PlacementContext.__index = PlacementContext

--- @param game Game
function PlacementContext.new(game)
	return setmetatable({ game = game }, PlacementContext)
end

function PlacementContext:card_w()
	return self.game.CARD_W
end

function PlacementContext:card_h()
	return self.game.CARD_H
end

function PlacementContext:tile_scale()
	return self.game.TILESCALE * self.game.TILESIZE
end

function PlacementContext:card_limit()
	return self.game.TABLE_HAND_SIZE or config.DEFAULT_CARD_LIMIT
end

function PlacementContext:controller()
	return self.game.INPUT
end

function PlacementContext:placement_area()
	local pt = self.game.placement_table
	return pt and pt.area
end

return PlacementContext
