--[[ jumbalaya-engine/util/utf8.lua - UTF-8 helpers (LuaJIT has no built-in utf8 library) ]]

local M = {}

M.pattern = "[%z\1-\127\194-\244][\128-\191]*"

function M.chars(s)
	return s:gmatch(M.pattern)
end

return M
