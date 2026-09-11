--[[
	app/core/persistence/save.lua - run snapshots, progress/settings writes,
	and session teardown.

	Game-specific restore/inventory logic lives in word_game/model/persistence/
	(WORD_GAME.Persistence). This module only orchestrates the engine snapshot
	format and delegates domain work through the facade.
]]

local BridgeRuntime = require("bridge.runtime")

local function persistence()
	return rawget(_G, "WORD_GAME") and WORD_GAME.Persistence
end

local function game()
	return BridgeRuntime.game()
end

function snapshot_for_action(action)
	local g = game()
	if not g then return end
	g.action = action
	queue_run_snapshot()
	g.action = nil
end

--- Collects store state plus game metadata and flags a pending run write.
function queue_run_snapshot()
	local g = game()
	if not g or g.F_NO_SAVING == true then return end
	local store = BridgeRuntime.store()
	local store_state = store and store:get()
	if not store_state then return end

	g.ARGS.run_snapshot = save_safe_clone{
		store = store_state,
		STATE = g.STATE,
		ACTION = g.action,
		BACK = store_state.selected_back and store_state.selected_back.save and store_state.selected_back:save() or nil,
		VERSION = g.VERSION,
	}
	local persist = persistence()
	if persist and persist.RunSave and persist.RunSave.append_pattern_row_snapshot then
		persist.RunSave.append_pattern_row_snapshot(g.ARGS.run_snapshot)
	end

	g.WRITE_FLAGS = g.WRITE_FLAGS or {}
	g.WRITE_FLAGS.run = true
	g.WRITE_FLAGS.update_queued = true
end

--- Deletes the stored run for the active profile, both on disk and in memory.
function delete_saved_run()
	local g = game()
	if not g then return end
	local profile_id = (g.SETTINGS and g.SETTINGS.profile) or 1
	love.filesystem.remove(profile_id..'/save.acs')
	g.STORED_RUN = nil
	if g.WRITE_FLAGS then g.WRITE_FLAGS.run = nil end
	if g.DISK_WORKER and g.DISK_WORKER.channel then
		g.DISK_WORKER.channel:push({
			op = 'purge',
			profile_num = profile_id,
		})
	end
end

--- Recollects live letter cards after load (delegates to WORD_GAME.Persistence).
function rebuild_card_inventory()
	local persist = persistence()
	if persist and persist.RunSave then
		persist.RunSave.rebuild_card_inventory()
	end
end

--- Feeds each stored area blob back into its live counterpart.
function restore_card_areas(save_table)
	local persist = persistence()
	if persist and persist.RunSave then
		persist.RunSave.restore_card_areas(save_table)
	end
end

--- Tears down all session UI/state (used when discarding a run or switching
--- profiles) and resets the stage machine.
function Game:discard_run()
	local domain = rawget(_G, "WORD_GAME")
	local scope = domain and (domain.RunScope or (domain.Run and domain.Run.Scope))
	if scope and scope.teardown then
		scope.teardown()
	end

	if self.ROOM then
		teardown_tree(self.STAGE_OBJECTS[self.STAGE])
		if self.buttons then self.buttons:remove(); self.buttons = nil end
		if self.deck_preview then self.deck_preview:remove(); self.deck_preview = nil end
		if self.MAIN_MENU_UI then self.MAIN_MENU_UI:remove(); self.MAIN_MENU_UI = nil end
		if self.SPLASH_FRONT then self.SPLASH_FRONT:remove(); self.SPLASH_FRONT = nil end
		if self.SPLASH_BACK then self.SPLASH_BACK:remove(); self.SPLASH_BACK = nil end
		if self.SPLASH_LOGO then self.SPLASH_LOGO:remove(); self.SPLASH_LOGO = nil end
		if self.GAME_OVER_UI then self.GAME_OVER_UI:remove(); self.GAME_OVER_UI = nil end
		if self.pattern_row then
			self.pattern_row.area = nil
		end
		if self.OVERLAY_MENU then self.OVERLAY_MENU:remove(); self.OVERLAY_MENU = nil end
		for key, value in pairs(self) do
			if (type(value) == "table") and value.is_kind and value:is_kind(CardArea) then
				self[key] = nil
			end
		end
		self.LIVE.CARD = {}
		self.LIVE.CARDAREA = {}
	end
	self.VIEWING_DECK = nil
	self.TIMELINE:flush()
	self.INPUT:shift_context_layer(-1000)
	self.INPUT.focus_cursor_stack = {}
	self.INPUT.focus_cursor_stack_level = 1

	self.STATE = -1
end

--- Flags a progress write (delegates UDA assembly to WORD_GAME.Persistence).
function Game:queue_progress_write()
	local persist = persistence()
	if persist and persist.Progress then
		persist.Progress.queue_progress_write()
	end
end

function Game:queue_settings_write()
	self.ARGS.settings_payload = self.SETTINGS
	self.WRITE_FLAGS = self.WRITE_FLAGS or {}
	self.WRITE_FLAGS.settings = true
	self.WRITE_FLAGS.update_queued = true
end

function Game:queue_metrics_write()
	self.ARGS.metrics_payload = self.METRICS
	self.WRITE_FLAGS = self.WRITE_FLAGS or {}
	self.WRITE_FLAGS.metrics = true
	self.WRITE_FLAGS.update_queued = true
end
