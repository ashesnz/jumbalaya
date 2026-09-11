--[[
	jumbalaya-engine/renderer.lua - Renderer interface and Love2D adapter.
]]

---@class Renderer
local Renderer = {}
Renderer.__index = Renderer

function Renderer.new(adapter)
	return setmetatable({ _adapter = adapter or love.graphics }, Renderer)
end

function Renderer:draw_card(view, rect)
	if self._adapter and self._adapter.draw_card then
		return self._adapter.draw_card(view, rect)
	end
end

function Renderer:draw_text(text, rect, style)
	if self._adapter and self._adapter.draw_text then
		return self._adapter.draw_text(text, rect, style)
	end
end

function Renderer:draw_sprite(atlas, quad, rect, color)
	if self._adapter and self._adapter.draw_sprite then
		return self._adapter.draw_sprite(atlas, quad, rect, color)
	end
end

return Renderer
