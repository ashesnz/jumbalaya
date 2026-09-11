--[[ app/bootstrap/engine_services_boot.lua - Phase 3: engine service context at boot ]]

local Engine = require("jumbalaya-engine")

local M = {}

function M.install()
	if not G then return nil end
	local store = G._store
	if not store then return nil end
	if G._engine and G._engine.store == store then
		return G._engine
	end

	G._engine = Engine.Context.new({ store = store })
	if WORD_GAME and WORD_GAME._bind_engine then
		WORD_GAME._bind_engine(G._engine)
	end
	return G._engine
end

return M
