function is_ui_container(node)
	return node.ui_kind == G.UI.COLUMN or node.ui_kind == G.UI.ROW or node.ui_kind == G.UI.ROOT
end
