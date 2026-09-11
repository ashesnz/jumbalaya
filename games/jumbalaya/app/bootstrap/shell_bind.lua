--[[ app/bootstrap/shell_bind.lua - Wire app callbacks into jumbalaya-engine.shell ]]

local shell = require("jumbalaya-engine.shell")

local M = {}

function M.install()
	shell.bind_app_events(require("app.bootstrap.app_events"))
	shell.bind_funcs(require("app.callbacks.funcs"))
	shell.bind_action_dispatch(require("app.input.action_dispatch"))
	shell.bind_game_access(require("word_game.model.game_access"))
end

return M
