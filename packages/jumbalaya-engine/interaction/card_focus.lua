--[[ app/core/input/card_focus.lua - Optional TABLE_BOARD card-focus hooks (installed at boot) ]]
local shell = require("jumbalaya-engine.shell")
local function g() return shell.game() end


local M = {
	hooks = {},
}

function M.install(hooks)
	M.hooks = hooks or {}
end

function M.is_table_card(node)
	if not node or not node:is_kind(Card) then return false end
	if node.facing ~= 'front' and not node.bonus_card then return false end
	if node.bonus_card then return true end
	local area = node.area
	if not area or not area.config then return false end
	local t = area.config.type
	return t == 'hand' or t == 'deck' or t == 'placement'
end

function M.bonus_stack_contains(node)
	local fn = M.hooks.bonus_stack_contains
	return fn and fn(node) or false
end

function M.hand_area()
	local fn = M.hooks.hand_area
	if fn then return fn() end
	for _, value in pairs(g()) do
		if type(value) == "table" and value.is_kind and value:is_kind(CardPile)
			and value.config and value.config.type == 'hand' then
			return value
		end
	end
	return nil
end

return M
