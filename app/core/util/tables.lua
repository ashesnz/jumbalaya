--[[
	app/core/util/tables.lua - table operations shared by engine and game code.

	`save_safe_clone` and `pack_to_source` must agree on the `"MANUAL_REPLACE"`
	sentinel: it marks live engine objects that cannot be serialized and are
	rebuilt by hand on load.
]]

local Kind = require("app.core.object")

--- Empties a table in place; tolerates nil and always yields a usable table.
function clear_table(t)
	if not t then return {} end
	for key in pairs(t) do t[key] = nil end
	return t
end

--- Tears down every entry, recursing into `.children` first and calling each
--  node's `remove`. Array entries go back-to-front so indices stay stable;
--  hash-keyed entries are swept afterwards.
function teardown_tree(t)
	for i = #t, 1, -1 do
		local entry = table.remove(t, i)
		if entry then
			if entry.children then teardown_tree(entry.children) end
			entry:remove()
		end
	end
	for _, entry in pairs(t) do
		if entry.children then teardown_tree(entry.children) end
		entry:remove()
	end
end

--- Finds the key whose value equals `wanted` (any key type), else nil.
function key_for_value(t, wanted)
	for key, value in pairs(t) do
		if value == wanted then return key end
	end
end

--- Total number of keys, array part and hash part combined.
function count_keys(t)
	local total = 0
	for _ in pairs(t) do total = total + 1 end
	return total
end

--- Drops nil holes by collecting only real values into a fresh array.
function compact_array(t)
	local kept = {}
	for _, value in pairs(t) do kept[#kept + 1] = value end
	return kept
end

--- Exchanges two slots in place; silently ignores missing arguments.
function swap_slots(t, i, j)
	if not t or not i or not j then return end
	t[i], t[j] = t[j], t[i]
end

--- Debug pretty-printer: renders a nested table as an indented string.
function dump_table(tbl, indent)
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
function by_order(first, second) return first.order < second.order end

--- Recursive clone: copies nested tables (and their metatables); leaves
--  non-table values untouched. Keys are cloned too, however exotic.
function deep_clone(value)
	if type(value) ~= 'table' then return value end
	local clone = {}
	for key, item in next, value, nil do clone[deep_clone(key)] = deep_clone(item) end
	return setmetatable(clone, deep_clone(getmetatable(value)))
end

--- Builds a save-safe shallow structure: engine objects (anything answering
--  `is_kind(Kind)`) collapse to the `"MANUAL_REPLACE"` sentinel string, plain
--  tables recurse, leaves pass through unchanged.
function save_safe_clone(source)
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

return {
	clear_table = clear_table,
	teardown_tree = teardown_tree,
	key_for_value = key_for_value,
	count_keys = count_keys,
	compact_array = compact_array,
	swap_slots = swap_slots,
	dump_table = dump_table,
	by_order = by_order,
	deep_clone = deep_clone,
	save_safe_clone = save_safe_clone,
}
