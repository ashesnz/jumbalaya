local M = {}

function M.refresh()
	G.ARGS = G.ARGS or {}
	G.ARGS.pending_layout = true
end

return M
