return function(InputRouter)
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
			if node:is_kind(Card)
				and (node.facing == 'front'
					or node.area == G.hand
					or node.area == (G.placement_table and G.placement_table.area)
					or node == G.deck
					or node.bonus_card
					or (WORD_GAME and WORD_GAME.BossWordStack and WORD_GAME.BossWordStack.contains(node)))
				and node.states.hover.can
				and not node.is_mascot then
				focusable = true
			end
			if node.config and node.config.force_focus then focusable = true end
			if node.config and node.config.button then focusable = true end
			if node.config and node.config.focus_args then
				-- Opt-out markers: 'none' type and funnel sources aren't directly focusable.
				focusable = not (node.config.focus_args.type == 'none' or node.config.focus_args.funnel_from)
			end
		end
	end
	return focusable
end
end
