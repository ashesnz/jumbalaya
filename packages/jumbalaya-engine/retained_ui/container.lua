
local BridgeRuntime = require("bridge.runtime")
local function g() return BridgeRuntime.game() end
function is_ui_container(node)
	return node.ui_kind == g().UI.COLUMN or node.ui_kind == g().UI.ROW or node.ui_kind == g().UI.ROOT
end
