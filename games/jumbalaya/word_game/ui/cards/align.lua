--[[ word_game/ui/cards/align.lua - Card layout alignment mixin (presentation) ]]

local M = {}

function M.install()
	function Card:align()
		if self.children.floating_sprite then
			self.children.floating_sprite.T.y = self.T.y
			self.children.floating_sprite.T.x = self.T.x
			self.children.floating_sprite.T.r = self.T.r
		end

		if self.children.focused_ui then self.children.focused_ui:set_alignment() end
	end
end

return M
