
local shell = require("jumbalaya-engine.shell")
local function g() return shell.game() end
function is_ui_container(node)
	return node.ui_kind == g().UI.COLUMN or node.ui_kind == g().UI.ROW or node.ui_kind == g().UI.ROOT
end
