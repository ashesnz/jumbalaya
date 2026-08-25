--[[
	app/core/object.lua - the Jumbalaya class system.

	Every reusable type in Jumbalaya descends from `Kind`. A new kind is
	declared with `Kind:derive("Name")` and fleshed out by implementing a
	`construct` method. Instances are created by calling the kind itself:
	`local thing = Thing(...)`.

	Method resolution rides the metatable chain instead of copying fields at
	derive time, so behaviour added to an ancestor is picked up immediately by
	every descendant, and each kind carries its own readable `kind_name`.
]]

---Root of the entire Jumbalaya type hierarchy.
---@class Kind
---@field kind_name string human-readable label for logs, dumps, and checks
---@field base Kind immediate ancestor of this kind
---@overload fun(self: Kind, ...): any
local Kind = {}
Kind.__index = Kind
Kind.kind_name = "Kind"

---Declare a subtype of this kind.
---@param name string label used by logs, save dumps, and type checks
---@return Kind subtype the freshly minted kind
function Kind:derive(name)
	local subtype = {
		kind_name = name or "Anonymous",
		base = self,
	}
	subtype.__index = subtype
	-- Metamethods are not inherited through __index, so re-link construction.
	subtype.__call = self.__call
	return setmetatable(subtype, self)
end

---Report whether this object belongs to `candidate` or descends from it.
---@param candidate table a kind produced by derive()
---@return boolean
function Kind:is_kind(candidate)
	local link = getmetatable(self)
	while link do
		if link == candidate then return true end
		link = getmetatable(link)
	end
	return false
end

---Calling a kind allocates an instance and runs its `construct` hook, if any.
---@param class table the kind being instantiated
function Kind.__call(class, ...)
	local instance = setmetatable({}, class)
	if class.construct then instance:construct(...) end
	return instance
end

return Kind
