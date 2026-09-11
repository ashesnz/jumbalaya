--[[
	jumbalaya-engine/adapters/love2d.lua - Love2D renderer adapter (wraps love.graphics).
]]

local M = {}

function M.renderer()
	return {
		draw_card = function(view, rect)
			if view and view.draw then
				view:draw()
				return
			end
			if view and view.sprite and view.sprite.draw then
				view.sprite:draw()
			end
		end,
		draw_text = function(text, rect, style)
			if not love or not love.graphics then return end
			style = style or {}
			if style.color then
				love.graphics.setColor(style.color)
			end
			if style.font then
				love.graphics.setFont(style.font)
			end
			love.graphics.print(text or "", rect.x or 0, rect.y or 0)
		end,
		draw_sprite = function(atlas, quad, rect, color)
			if not love or not love.graphics or not atlas then return end
			if color then
				love.graphics.setColor(color)
			end
			local x = rect and rect.x or 0
			local y = rect and rect.y or 0
			if quad then
				love.graphics.draw(atlas, quad, x, y)
			elseif atlas.draw then
				atlas:draw(x, y)
			elseif atlas.image then
				love.graphics.draw(atlas.image, x, y)
			end
		end,
	}
end

return M
