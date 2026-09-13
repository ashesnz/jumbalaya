--[[ games/jumbalaya/bootstrap_paths.lua - package.path for monorepo layout ]]

local M = {}

local function ends_with(path, suffix)
	return path:sub(-#suffix) == suffix
end

function M.resolve()
	local source = love.filesystem.getSource()
	local game_root
	local repo_root
	local test_root

	if ends_with(source, "/tests") or ends_with(source, "\\tests") then
		test_root = source
		local parent = source:match("^(.+)[/\\]tests$")
		local game_main = parent .. "/games/jumbalaya/main.lua"
		local has_game_layout = (love.filesystem and love.filesystem.getInfo(game_main))
			or (io.open(game_main, "r") ~= nil)
		if has_game_layout then
			game_root = parent .. "/games/jumbalaya"
			repo_root = parent
		else
			game_root = parent
			repo_root = parent .. "/../.."
		end
	elseif source:match("[/\\]games[/\\]jumbalaya$") then
		game_root = source
		repo_root = source .. "/../.."
	elseif love.filesystem.getInfo("games/jumbalaya/main.lua") then
		game_root = source .. "/games/jumbalaya"
		repo_root = source
	else
		game_root = source
		repo_root = source .. "/../.."
	end

	M.source = source
	M.game_root = game_root
	M.repo_root = repo_root
	M.test_root = test_root
	return M
end

local function mount_game_assets_if_needed(paths)
	if not (love and love.filesystem and love.filesystem.mount) then
		return
	end
	if paths.game_root == paths.source then
		return
	end
	-- Repo-root shim (`love .`): mount the full game tree (assets, localization, shaders).
	love.filesystem.mount(paths.game_root, "/", true)
end

function M.install()
	local paths = M.resolve()
	local chunks = {
		paths.repo_root .. "/packages/?.lua",
		paths.repo_root .. "/packages/?/init.lua",
		paths.game_root .. "/?.lua",
		paths.game_root .. "/?/init.lua",
	}
	if paths.test_root then
		chunks[#chunks + 1] = paths.test_root .. "/?.lua"
		chunks[#chunks + 1] = paths.test_root .. "/?/init.lua"
	end
	package.path = table.concat(chunks, ";") .. ";" .. package.path
	mount_game_assets_if_needed(paths)
	return paths
end

function M.path_under_game(...)
	return M.game_root .. "/" .. table.concat({ ... }, "/")
end

function M.path_under_repo(...)
	return M.repo_root .. "/" .. table.concat({ ... }, "/")
end

return M
