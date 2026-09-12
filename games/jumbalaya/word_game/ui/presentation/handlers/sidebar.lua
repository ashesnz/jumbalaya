--[[ word_game/ui/presentation/handlers/sidebar.lua - Sidebar HUD presentation hooks ]]

local M = {}

function M.register(Presentation, ctx)
	local ui = ctx.ui
	local runtime = ctx.runtime

	runtime().notify_display_changed = function()
		if runtime().STAGE == runtime().STAGES.RUN and ui.Sidebar then
			ui.Sidebar.rebuild()
		end
	end

	Presentation.on("sidebar_refresh", function()
		if ui.Sidebar then
			ui.Sidebar:refresh()
		end
	end)

	Presentation.on("sidebar_ensure", function()
		if ui.Sidebar then
			ui.Sidebar:ensure()
		end
	end)

	Presentation.on("sidebar_clear_hand", function()
		if ui.Sidebar and ui.Sidebar.clear_hand then
			ui.Sidebar:clear_hand()
		end
	end)

	Presentation.on("sidebar_sync_visibility", function()
		if ui.Sidebar and ui.Sidebar.sync_visibility then
			ui.Sidebar.sync_visibility()
		end
	end)

	Presentation.on("hand_shuffle_sync_position", function()
		if ui.TableControls and ui.TableControls.sync_position then
			ui.TableControls.sync_position()
		end
	end)

	Presentation.on("hand_shuffle_sync", function()
		if ui.TableControls and ui.TableControls.sync then
			ui.TableControls.sync()
		end
	end)

	Presentation.on("table_deck_reset", function()
		if ui.TableDeck and ui.TableDeck.reset then
			ui.TableDeck.reset()
		end
	end)
end

return M
