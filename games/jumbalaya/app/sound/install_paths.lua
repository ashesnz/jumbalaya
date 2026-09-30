--[[ app/sound/install_paths.lua - package.path + asset mount for audio worker threads ]]

local root = love.filesystem.getSource()
package.path = root .. "/?.lua;"
	.. root .. "/?/init.lua;"
	.. package.path

local paths = require("bootstrap_paths").install()
local AudioSource = require("jumbalaya-engine.adapters.love2d.audio_source")
AudioSource.set_asset_root(paths.game_root)

return true
