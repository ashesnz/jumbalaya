--[[ word_game/ui/widgets/press.lua - Catalog string → function callback ]]

local Funcs = require("app.callbacks.funcs")

local M = {}

--- Returns a click/update handler that dispatches a remaining Funcs name.
function M.named(name)
	return function(node, ...)
		return Funcs.dispatch(name, node, ...)
	end
end

return M
