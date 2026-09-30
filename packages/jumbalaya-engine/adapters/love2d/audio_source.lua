--[[ jumbalaya-engine/adapters/love2d/audio_source.lua - Load OGG via love FS or disk (monorepo / repo-root launch) ]]

local M = {}

local asset_root = nil
local SOUNDS_DIR = "resources/sounds"

local function stream_or_static(kind)
	return (kind ~= "sfx") and "stream" or "static"
end

function M.set_asset_root(root)
	asset_root = root
end

function M.get_asset_root()
	return asset_root
end

function M.absolute_path(rel_path)
	if not asset_root then return nil end
	return asset_root .. "/" .. rel_path
end

--- Load a decoded source from the virtual FS or from disk under asset_root.
function M.new_source(code, kind)
	if not (love and love.audio and love.audio.newSource) then
		return nil
	end
	local rel = SOUNDS_DIR .. "/" .. code .. ".ogg"
	local stype = stream_or_static(kind)

	if love.filesystem.getInfo(rel) then
		local ok, src = pcall(love.audio.newSource, rel, stype)
		if ok and src then return src end
	end

	local abs = M.absolute_path(rel)
	if not abs then return nil end
	local file = io.open(abs, "rb")
	if not file then return nil end
	local bytes = file:read("*a")
	file:close()
	if not bytes or bytes == "" then return nil end

	local leaf = code .. ".ogg"
	local ok_data, file_data = pcall(love.filesystem.newFileData, bytes, leaf)
	if not ok_data or not file_data then return nil end
	local ok_src, src = pcall(love.audio.newSource, file_data, stype)
	if ok_src and src then return src end
	return nil
end

local function append_ogg_names(names, filename)
	if type(filename) == "string" and filename:sub(-4) == ".ogg" then
		names[#names + 1] = filename
	end
end

local function list_from_love_fs()
	local names = {}
	local ok, listing = pcall(love.filesystem.getDirectoryItems, SOUNDS_DIR)
	if ok and listing then
		for _, filename in ipairs(listing) do
			append_ogg_names(names, filename)
		end
	end
	return names
end

local function list_from_disk()
	local names = {}
	if not asset_root then return names end
	local abs_dir = asset_root .. "/" .. SOUNDS_DIR
	local handle = io.popen(string.format('find %q -maxdepth 1 -name "*.ogg" -print 2>/dev/null', abs_dir))
	if not handle then return names end
	for line in handle:lines() do
		append_ogg_names(names, line:match("([^/]+)$"))
	end
	handle:close()
	return names
end

--- Basenames of .ogg files (e.g. "Title.ogg") for preload.
function M.list_ogg_files()
	local names = list_from_love_fs()
	if #names > 0 then return names end
	return list_from_disk()
end

return M
