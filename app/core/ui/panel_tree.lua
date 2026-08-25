return function(Target)
function LayoutView:find_node_by_id(id, node)
	node = node or self.root_node
	if node.config and node.config.id == id then return node end
	for _, v in pairs(node.children) do
		local found = self:find_node_by_id(id, v)
		if found then return found end
		if v.config.object and v.config.object.find_node_by_id then
			found = v.config.object:find_node_by_id(id, nil)
			if found then return found end
		end
	end
	return nil
end

--- Collects every element tagged with `config.group == group`.
function LayoutView:get_group(node, group, ingroup)
	node = node or self.root_node
	ingroup = ingroup or {}
	for _, v in pairs(node.children) do
		self:get_group(v, group, ingroup)
	end
	if node.config and node.config.group and node.config.group == group then
		table.insert(ingroup, node)
	end
	return ingroup
end

--- Removes every member of a named group from the tree and relayouts.
--  Relayout runs at each recursion level so parents shrink as children go.
function LayoutView:remove_group(node, group)
	node = node or self.root_node
	for k, v in pairs(node.children) do
		if self:remove_group(v, group) then node.children[k] = nil end
	end
	if node.config and node.config.group and node.config.group == group then
		node:remove()
		return true
	end

	self:calculate_xywh(self.root_node, self.T, true)
	self.root_node:set_wh()
	self.root_node:set_alignment()
end

--- Creates a LayoutNode for `node`, wires inheritance (group/button), recurses
--- into container children, and attaches the result to its parent's tree.
function LayoutView:attach_node(node, parent)
	local ui_e = LayoutNode(parent, self, node.n, node.config)

	-- Children inherit their parent's group tag...
	if parent and parent.config and parent.config.group then
		if ui_e.config then ui_e.config.group = parent.config.group
		else ui_e.config = {group = parent.config.group} end
	end
	-- ...and button linkage (nested buttons click their outer button too).
	if parent and parent.config and parent.config.button then
		if ui_e.config then ui_e.config.button_UIE = parent
		else ui_e.config = {button_UIE = parent} end
	end
	if parent and parent.config and parent.config.button_UIE then
		if ui_e.config then ui_e.config.button_UIE = parent.config.button_UIE
		else ui_e.config = {button = parent.config.button} end
	end

	-- An embedded object that itself carries the button shouldn't compete
	-- for clicks with the element wrapping it.
	if node.n and node.n == G.UI.OBJECT and ui_e.config.button then
		ui_e.config.object.states.click.can = false
	end

	if (node.n and node.n == G.UI.COLUMN or node.n == G.UI.ROW or node.n == G.UI.ROOT) and node.nodes then
		for _, v in pairs(node.nodes) do
			self:attach_node(v, ui_e)
		end
	end

	if not parent then
		self.root_node = ui_e
		self.root_node.parent = self
	else
		table.insert(parent.children, ui_e)
	end
	if node.config and node.config.mid then self.Mid = ui_e end
end
end
