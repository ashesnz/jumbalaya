return function(Node)
	function Node:drag()
		if not (self.config and self.config.d_popup) then return end
		if self.children.d_popup then return end

		self.children.d_popup = LayoutView{
			definition = self.config.d_popup,
			config = self.config.d_popup_config,
		}
		self.children.d_popup.states.collide.can = false
		table.insert(G.LIVE.POPUP, self.children.d_popup)
		self.children.d_popup.states.drag.can = true
	end

	function Node:can_drag()
		return self.states.drag.can and self or nil
	end

	function Node:stop_drag()
		if not self.children.d_popup then return end
		for k, v in pairs(G.LIVE.POPUP) do
			if v == self.children.d_popup then
				table.remove(G.LIVE.POPUP, k)
				break
			end
		end
		self.children.d_popup:remove()
		self.children.d_popup = nil
	end

	function Node:hover()
		if not (self.config and self.config.h_popup) then return end
		if self.children.h_popup then return end

		self.config.h_popup_config.instance_type = "POPUP"
		self.children.h_popup = LayoutView{
			definition = self.config.h_popup,
			config = self.config.h_popup_config,
		}
		self.children.h_popup.states.collide.can = false
		self.children.h_popup.states.drag.can = true
	end

	function Node:stop_hover()
		if not self.children.h_popup then return end
		self.children.h_popup:remove()
		self.children.h_popup = nil
	end

	function Node:set_container(container)
		if self.children then
			for _, child in pairs(self.children) do child:set_container(container) end
		end
		self.container = container
	end

	function Node:remove()
		for _, registry in ipairs({ G.LIVE and G.LIVE.POPUP, G.LIVE and G.LIVE.NODE, G.STAGE_OBJECTS and G.STAGE_OBJECTS[G.STAGE] }) do
			for k, v in ipairs(registry or {}) do
				if v == self then
					table.remove(registry, k)
					break
				end
			end
		end

		if self.children then
			for _, child in pairs(self.children) do child:remove() end
		end

		local controller = G.INPUT or {}
		for _, input_state in ipairs({ "clicked", "focused", "dragging", "hovering", "released_on", "press_state", "release_state", "hover_state" }) do
			local state = controller[input_state]
			if state and state.target == self then state.target = nil end
		end

		self.REMOVED = true
	end

	function Node:release(dragged) end
	function Node:click() end
	function Node:animate() end
	function Node:update(dt) end
end
