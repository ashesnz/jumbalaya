--[[ word_game/ui/cards/alerts.lua - Collection-screen alert badge mixin ]]

local UIViewHost = require("jumbalaya-engine.panels.view_host")

local M = {}

function M.install()
	function Card:update_alert()
		if (self.ability.set == 'Companion' or self.ability.set == 'Perk' or self.ability.usable or self.ability.set == 'Finish') then
			if self.area and self.area.config.collection and self.config.center then
				if self.config.center.alerted and self.children.alert then
					self.children.alert:remove()
					self.children.alert = nil
				elseif not self.config.center.alerted and not self.children.alert and self.config.center.discovered then
					self.children.alert = UIViewHost.create{
						definition = build_card_alert(),
						config = {
							align = (self.ability.set == 'Perk' and (self.config.center.order % 2) == 1) and "tli" or "tri",
							offset = {
								x = (self.ability.set == 'Perk' and (self.config.center.order % 2) == 1) and 0.1 or -0.1,
								y = 0.1,
							},
							parent = self,
						},
					}
				end
			end
		end
	end
end

return M
