--[[
	jumbalaya-engine/util/tables.lua - table operations shared by engine and game code.

	`save_safe_clone` and `pack_to_source` must agree on the `"MANUAL_REPLACE"`
	sentinel: it marks live engine objects that cannot be serialized and are
	rebuilt by hand on load.

	Prefer `local Tables = require("jumbalaya-engine.util.tables")` in new code.
	Boot calls `Tables.install()` for legacy global aliases.
]]

local Kind = require("jumbalaya-engine.object")

local M = {}

--- Empties a table in place; tolerates nil and always yields a usable table.
function M.clear_table(t)
	if not t then return {} end
	for key in pairs(t) do t[key] = nil end
	return t
end

--- Tears down every entry, recursing into `.children` first and calling each
--  node's `remove`. Array entries go back-to-front so indices stay stable;
--  hash-keyed entries are swept afterwards.
function M.teardown_tree(t)
	for i = #t, 1, -1 do
		local entry = table.remove(t, i)
		if entry then
			if entry.children then M.teardown_tree(entry.children) end
			entry:remove()
		end
	end
	for _, entry in pairs(t) do
		if entry.children then M.teardown_tree(entry.children) end
		entry:remove()
	end
end

--- Finds the key whose value equals `wanted` (any key type), else nil.
function M.key_for_value(t, wanted)
	for key, value in pairs(t) do
		if value == wanted then return key end
	end
end

--- Total number of keys, array part and hash part combined.
function M.count_keys(t)
	local total = 0
	for _ in pairs(t) do total = total + 1 end
	return total
end

--- Drops nil holes by collecting only real values into a fresh array.
function M.compact_array(t)
	local kept = {}
	for _, value in pairs(t) do kept[#kept + 1] = value end
	return kept
end

--- Removes the first matching value with swap-with-last (O(1) for dense arrays).
function M.remove_swap_last(registry, wanted)
	if not registry or not wanted then return false end
	for index, value in ipairs(registry) do
		if value == wanted then
			local last = #registry
			registry[index] = registry[last]
			registry[last] = nil
			return true
		end
	end
	return false
end

--- Exchanges two slots in place; silently ignores missing arguments.
function M.swap_slots(t, i, j)
	if not t or not i or not j then return end
	t[i], t[j] = t[j], t[i]
end

--- Debug pretty-printer: renders a nested table as an indented string.
function M.dump_table(tbl, indent)
	indent = indent or 0
	local rendered = {}
	local pad = string.rep(" ", indent)

	rendered[#rendered + 1] = pad .. "{\n"
	local inner = string.rep(" ", indent + 2)
	for key, value in pairs(tbl) do
		local label = ("[%s] = "):format(tostring(key))
		local shown = type(value) == "table"
			and tostring(value)
			or ("%q"):format(tostring(value))
		rendered[#rendered + 1] = inner .. label .. shown .. ",\n"
	end
	rendered[#rendered + 1] = pad .. "}\n"
	return table.concat(rendered)
end

--- Comparator ordering items by their `order` field.
function M.by_order(first, second) return first.order < second.order end

--- Recursive clone: copies nested tables (and their metatables); leaves
--  non-table values untouched. Keys are cloned too, however exotic.
function M.deep_clone(value)
	if type(value) ~= 'table' then return value end
	local clone = {}
	for key, item in next, value, nil do clone[M.deep_clone(key)] = M.deep_clone(item) end
	return setmetatable(clone, M.deep_clone(getmetatable(value)))
end

--- Builds a save-safe shallow structure: engine objects (anything answering
--  `is_kind(Kind)`) collapse to the `"MANUAL_REPLACE"` sentinel string, plain
--  tables recurse, leaves pass through unchanged.
function M.save_safe_clone(source)
	local function walk(branch)
		local result = {}
		for key, value in pairs(branch) do
			if type(value) == 'table' then
				result[key] = (value.is_kind and value:is_kind(Kind))
					and '"MANUAL_REPLACE"'
					or walk(value)
			else
				result[key] = value
			end
		end
		return result
	end
	return walk(source)
end

--- Install legacy global aliases expected by Love2D boot and card class mixins.
function M.install()
	_G.clear_table = M.clear_table
	_G.teardown_tree = M.teardown_tree
	_G.key_for_value = M.key_for_value
	_G.count_keys = M.count_keys
	_G.swap_slots = M.swap_slots
	_G.dump_table = M.dump_table
	_G.by_order = M.by_order
	_G.deep_clone = M.deep_clone
	_G.save_safe_clone = M.save_safe_clone
end

return M
