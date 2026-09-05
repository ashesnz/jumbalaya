--[[
	app/core/persistence/save.lua - run snapshots, progress/settings writes,
	and session teardown.
]]

function snapshot_for_action(action)
	G.action = action
	queue_run_snapshot()
	G.action = nil
end

--- Collects every CardArea's serialized state plus game metadata and flags a
--- pending run write.
function queue_run_snapshot()
	if G.F_NO_SAVING == true then return end
	local card_areas = {}
	for name, value in pairs(G) do
		if type(value) == "table" and value.is_kind and value:is_kind(CardArea) then
			local serialized = value:save()
			if serialized then card_areas[name] = serialized end
		end
	end

	G.ARGS.run_snapshot = save_safe_clone{
		cardAreas = card_areas,
		GAME = G.GAME,
		STATE = G.STATE,
		ACTION = G.action,
		BACK = G.GAME.selected_back:save(),
		VERSION = G.VERSION
	}
	if G.placement_table and G.placement_table.area then
		local serialized = G.placement_table.area:save()
		if serialized then
			G.ARGS.run_snapshot.cardAreas.placement_table = serialized
		end
	end

	G.WRITE_FLAGS = G.WRITE_FLAGS or {}
	G.WRITE_FLAGS.run = true
	G.WRITE_FLAGS.update_queued = true
end

--- Deletes the stored run for the active profile, both on disk and in memory.
function delete_saved_run()
	local profile_id = (G.SETTINGS and G.SETTINGS.profile) or 1
	love.filesystem.remove(profile_id..'/save.acs')
	G.STORED_RUN = nil
	if G.WRITE_FLAGS then G.WRITE_FLAGS.run = nil end
	if G.DISK_WORKER and G.DISK_WORKER.channel then
		G.DISK_WORKER.channel:push({
			op = 'purge',
			profile_num = profile_id,
		})
	end
end

--- Recollects the live letter cards spread across all areas after a load,
--- reassigning sequential ids and widening the vault to fit them.
function rebuild_card_inventory()
	G.playing_cards = {}
	local seen = {}
	local max_id = 0
	local areas = {
		G.deck, G.hand, G.discard,
		G.placement_table and G.placement_table.area,
	}
	for _, area in ipairs(areas) do
		if area and area.cards then
			for _, card in ipairs(area.cards) do
				local id = card.playing_card
				if id and not seen[id] then
					seen[id] = true
					G.playing_cards[#G.playing_cards + 1] = card
					if id > max_id then max_id = id end
				end
			end
		end
	end
	G.playing_card = max_id
	if G.deck and G.deck.config and #G.playing_cards > 0 then
		G.deck.config.card_limit = math.max(G.deck.config.card_limit or 52, #G.playing_cards)
	end
	if G.GAME then G.GAME.starting_deck_size = #G.playing_cards end
end

--- Feeds each stored area blob back into its live counterpart.
function restore_card_areas(save_table)
	if not save_table or not save_table.cardAreas then return end
	for name, data in pairs(save_table.cardAreas) do
		if name == 'placement_slots' or name == 'placement_table' then
			if G.placement_table and G.placement_table.area then
				G.placement_table.area:load(data)
			end
		else
			local area = G[name]
			if area and area.load then area:load(data) end
		end
	end
	rebuild_card_inventory()
end

--- Tears down all session UI/state (used when discarding a run or switching
--- profiles) and resets the stage machine.
function Game:discard_run()
	local RunScope = require("word_game.model.run_scope")
	RunScope.teardown()

	if self.ROOM then
		teardown_tree(G.STAGE_OBJECTS[G.STAGE])
		if self.buttons then self.buttons:remove(); self.buttons = nil end
		if self.deck_preview then self.deck_preview:remove(); self.deck_preview = nil end
		if self.MAIN_MENU_UI then self.MAIN_MENU_UI:remove(); self.MAIN_MENU_UI = nil end
		if self.SPLASH_FRONT then self.SPLASH_FRONT:remove(); self.SPLASH_FRONT = nil end
		if self.SPLASH_BACK then self.SPLASH_BACK:remove(); self.SPLASH_BACK = nil end
		if self.SPLASH_LOGO then self.SPLASH_LOGO:remove(); self.SPLASH_LOGO = nil end
		if self.GAME_OVER_UI then self.GAME_OVER_UI:remove(); self.GAME_OVER_UI = nil end
		if self.placement_table then
			self.placement_table.area = nil
		end
		if self.OVERLAY_MENU then self.OVERLAY_MENU:remove(); self.OVERLAY_MENU = nil end
		if self.OVERLAY_TUTORIAL then
			if G.OVERLAY_TUTORIAL.content then G.OVERLAY_TUTORIAL.content:remove() end
			G.OVERLAY_TUTORIAL:remove()
			G.OVERLAY_TUTORIAL = nil
		end
		if self.INTRO_OVERLAY then
			self.INTRO_OVERLAY:remove()
			self.INTRO_OVERLAY = nil
		end
		for key, value in pairs(G) do
			if (type(value) == "table") and value.is_kind and value:is_kind(CardArea) then
				G[key] = nil
			end
		end
		G.LIVE.CARD = {}
		G.LIVE.CARDAREA = {}
	end
	G.VIEWING_DECK = nil
	G.TIMELINE:flush()
	G.INPUT:shift_context_layer(-1000)
	G.INPUT.focus_cursor_stack = {}
	G.INPUT.focus_cursor_stack_level = 1

	G.STATE = -1
end

--- Flags a progress write: unlock/discovery/alert badges per card definition,
--- plus the settings and profile payloads.
function Game:queue_progress_write()
	G.ARGS.progress_payload = G.ARGS.progress_payload or {}
	G.ARGS.progress_payload.UDA = clear_table(G.ARGS.progress_payload.UDA)
	G.ARGS.progress_payload.SETTINGS = G.SETTINGS
	G.ARGS.progress_payload.PROFILE = G.PROFILES[G.SETTINGS.profile]

	for key, definition in pairs(self.P_CENTERS) do
		G.ARGS.progress_payload.UDA[key] =
			(definition.unlocked and 'u' or '')..
			(definition.discovered and 'd' or '')..
			(definition.alerted and 'a' or '')
	end

	G.WRITE_FLAGS = G.WRITE_FLAGS or {}
	G.WRITE_FLAGS.progress = true
	G.WRITE_FLAGS.update_queued = true
end

function Game:queue_settings_write()
	G.ARGS.settings_payload = G.SETTINGS
	G.WRITE_FLAGS = G.WRITE_FLAGS or {}
	G.WRITE_FLAGS.settings = true
	G.WRITE_FLAGS.update_queued = true
end

function Game:queue_metrics_write()
	G.ARGS.metrics_payload = G.METRICS
	G.WRITE_FLAGS = G.WRITE_FLAGS or {}
	G.WRITE_FLAGS.metrics = true
	G.WRITE_FLAGS.update_queued = true
end
