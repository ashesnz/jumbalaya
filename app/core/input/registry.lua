return function(InputRouter)
function InputRouter:cull_registry()
	for _, registry in pairs(self.button_registry) do
		for i = #registry, 1, -1 do
			if registry[i].node.REMOVED then table.remove(registry, i) end
		end
	end
end

--- Binds `node` to a gamepad button. The newest binding wins; older ones stay
--- behind as fallback if the new node goes away.
---@param node SceneNode
---@param registry string valid gamepad input name
function InputRouter:add_to_registry(node, registry)
	self.button_registry[registry] = self.button_registry[registry] or {}
	table.insert(self.button_registry[registry], 1, {
		node = node,
		menu = (not not G.OVERLAY_MENU) or (not not G.SETTINGS.paused),
	})
end

--- Fires queued clicks whose recorded menu-context matches the current one
--- and whose node sits within the room bounds.
function InputRouter:process_registry()
	for _, registry in pairs(self.button_registry) do
		for i = 1, #registry do
			local entry = registry[i]
			if entry.click and entry.node.click then
				local in_bounds = entry.node.T.x > -2 and entry.node.T.x < G.ROOM.T.w + 2
					and entry.node.T.y > -2 and entry.node.T.y < G.ROOM.T.h + 2
				if entry.menu == (not not G.OVERLAY_MENU) and in_bounds then
					entry.node:click()
				end
				entry.click = nil
			end
		end
	end
end
end
