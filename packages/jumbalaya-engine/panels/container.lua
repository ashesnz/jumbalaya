
local shell = require("jumbalaya-engine.shell")
local game = shell.game
function is_ui_container(node)
	return node.ui_kind == game().UI.COLUMN or node.ui_kind == game().UI.ROW or node.ui_kind == game().UI.ROOT
end
