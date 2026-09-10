return function(InputRouter)
local CardFocus = require("app.core.input.card_focus")

function InputRouter:is_node_focusable(node)
	local focusable = false
	if node.T.y > G.ROOM.T.h + 3 then return false end

	if not node.REMOVED and not node.under_overlay
		and (node.states.hover.can and not self.dragging.target or self.dragging.target == node)
		and ((not not node.created_on_pause) == (not not G.SETTINGS.paused))
		and node.states.visible
		and (not node.LayoutView or node.LayoutView.states.visible) then
		if self.screen_keyboard then
			focusable = node.LayoutView == self.screen_keyboard and not not node.config.button
		else
			if CardFocus.is_table_card(node) or CardFocus.bonus_stack_contains(node) then
				if node.states.hover.can and not node.is_mascot then
					focusable = true
				end
			end
			if node.config and node.config.force_focus then focusable = true end
			if node.config and node.config.button then focusable = true end
			if node.config and node.config.focus_args then
				focusable = not (node.config.focus_args.type == 'none' or node.config.focus_args.funnel_from)
			end
		end
	end
	return focusable
end
end
