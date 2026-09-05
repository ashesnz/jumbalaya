
local Scheduler = require "app.effects.timeline_scheduler"
local Easing = require "app.effects.easing"

return function(ctx)
	local PlayerHost = ctx.PlayerHost
	local Layout = ctx.Layout
	local CharacterSpeech = ctx.CharacterSpeech
	local state = ctx.state
	local STAGE3_DIM_TIME = ctx.STAGE3_DIM_TIME
	local STAGE3_SLIDE_TIME = ctx.STAGE3_SLIDE_TIME
	local STAGE3_BOSS_DROP_TIME = ctx.STAGE3_BOSS_DROP_TIME
	local STAGE3_BOSS_BEAT = ctx.STAGE3_BOSS_BEAT
	local STAGE23_GUEST_LINES = ctx.STAGE23_GUEST_LINES

	function PlayerHost.begin_marco_play()
		local rs = state.get()
		if not rs then return end
		rs.cinematic_seen = rs.cinematic_seen or {}
		rs.cinematic_seen["1-7"] = true
		rs.marco_cinematic_seen = true
		rs.stage3_cinematic = nil
		rs.stage3_portrait_rect = nil
		rs.stage3_portrait_pose = "left"
		rs.stage3_boss_portrait_rect = nil
		rs.stage3_ally_portrait_rect = nil
		rs.stage3_ally_visible = true
		rs.stage3_ally_index = 1
		rs.stage3_guest_portrait_rect = nil
		rs.stage3_guest_visible = true
		rs.stage3_guest_index = 2
		rs.stage3_guest_pose = "rest"
		rs.stage3_guest_line = nil
		rs.stage3_slide_started = nil
		rs.stage3_active_turn = "milo"
		local host = G.player_host
		if host then
			host:remove_speech_bubble()
			host:apply_screen_position()
		end
		if WORD_GAME and WORD_GAME.AllyHost then
			WORD_GAME.AllyHost.clear()
		end
		if WORD_GAME and WORD_GAME.GuestHost then
			WORD_GAME.GuestHost.clear()
		end
		PlayerHost.clear_spotlight()
		PlayerHost.refresh_card_input()
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.show_marco_line(index)
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		local key = STAGE23_GUEST_LINES[index]
		if not key then
			PlayerHost.slide_marco_to_party()
			return
		end
		rs.stage3_guest_line = index
		if WORD_GAME and WORD_GAME.GuestHost then
			WORD_GAME.GuestHost.say(key)
		end
		PlayerHost.sync_spotlight("milo_stage23_guest_talk")
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.slide_marco_to_party()
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		if WORD_GAME and WORD_GAME.GuestHost then
			WORD_GAME.GuestHost.clear()
		end
		rs.stage3_guest_line = nil
		local from = Layout.guest_portrait_rect()
		local dest = Layout.cinematic_guest_rest_rect()
		rs.stage3_guest_portrait_rect = {
			x = from.x,
			y = from.y,
			w = from.w,
			h = from.h,
		}
		PlayerHost.sync_spotlight("milo_stage23_guest")
		Easing.value{ref_table = rs.stage3_guest_portrait_rect, ref_value = "x", mod = dest.x - from.x, timer = "REAL", not_blockable = true, delay = STAGE3_SLIDE_TIME, ease = "quad"}
		Scheduler.add{
			mode = "delayed",
			delay = STAGE3_SLIDE_TIME,
			blockable = false,
			blocking = false,
			func = function()
				if rs.stage3_cinematic then
					rs.stage3_guest_portrait_rect = nil
					rs.stage3_guest_pose = "rest"
					PlayerHost.begin_marco_play()
				end
				return true
			end,
		}
	end

	function PlayerHost.drop_marco()
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		local dest = Layout.hud_portrait_rect()
		local start_y = dest.y - dest.h - math.max(1.2, G.TILE_H * 0.22)
		rs.stage3_guest_visible = true
		rs.stage3_guest_index = 2
		rs.stage3_guest_pose = "center"
		rs.stage3_guest_portrait_rect = {
			x = dest.x,
			y = start_y,
			w = dest.w,
			h = dest.h,
		}
		PlayerHost.sync_spotlight("milo_stage23_guest")
		if WORD_GAME and WORD_GAME.GuestHost then
			WORD_GAME.GuestHost.ensure()
		end
		Easing.value{ref_table = rs.stage3_guest_portrait_rect, ref_value = "y", mod = dest.y - start_y, timer = "REAL", not_blockable = true, delay = STAGE3_BOSS_DROP_TIME, ease = "quad"}
		Scheduler.add{
			mode = "delayed",
			delay = STAGE3_BOSS_DROP_TIME,
			blockable = false,
			blocking = false,
			func = function()
				if not rs.stage3_cinematic then return true end
				rs.stage3_guest_portrait_rect = nil
				PlayerHost.show_marco_line(1)
				return true
			end,
		}
	end

	function PlayerHost.schedule_marco_drop()
		local rs = state.get()
		if not rs or rs.stage3_guest_started then return end
		rs.stage3_guest_started = true
		local wait = CharacterSpeech.duration("boss_stage23_intro") + STAGE3_BOSS_BEAT
		Scheduler.add{
			mode = "delayed",
			delay = wait,
			blockable = false,
			blocking = false,
			func = function()
				if state.get() and state.get().stage3_cinematic then
					PlayerHost.drop_marco()
				end
				return true
			end,
		}
	end

	function PlayerHost.reset_marco_cinematic_state()
		local rs = state.get()
		if not rs then return end
		if WORD_GAME and WORD_GAME.Characters then
			WORD_GAME.Characters.set_current("milo")
		end
		rs.stage3_portrait_pose = "left"
		rs.stage3_portrait_visible = true
		rs.stage3_portrait_rect = nil
		rs.stage3_slide_started = true
		rs.stage3_boss_visible = nil
		rs.stage3_boss_portrait_rect = nil
		rs.stage3_boss_index = nil
		rs.stage3_boss_started = nil
		rs.stage3_ally_visible = true
		rs.stage3_ally_portrait_rect = nil
		rs.stage3_ally_index = 1
		rs.stage3_ally_started = true
		rs.stage3_ally_line = nil
		rs.stage3_guest_visible = nil
		rs.stage3_guest_portrait_rect = nil
		rs.stage3_guest_index = 2
		rs.stage3_guest_pose = "center"
		rs.stage3_guest_started = nil
		rs.stage3_guest_line = nil
		rs.stage3_active_turn = nil
		rs.stage3_scoring_turn = nil
	end

	function PlayerHost.maybe_marco_cinematic()
		if G.STATE ~= G.STATES.TABLE_BOARD then return end
		local wr = G.GAME and G.GAME.word_round
		if not wr then return end
		local round_config = require("word_game.config.round_config")
		if not round_config.is_marco_cinematic_hand(wr.set, wr.hand_index) then return end
		local rs = state.get()
		if not rs then return end
		local seen = rs.cinematic_seen or {}
		if seen["1-7"] or rs.marco_cinematic_seen then return end
		if rs.stage3_cinematic then return end

		PlayerHost.reset_marco_cinematic_state()
		rs.stage3_cinematic = true
		PlayerHost.ensure()
		local host = G.player_host
		if host then
			host:remove_speech_bubble()
			host:apply_screen_position()
		end
		PlayerHost.sync_spotlight("milo_stage23_dim")
		Scheduler.add{
			mode = "delayed",
			delay = STAGE3_DIM_TIME + STAGE3_BOSS_BEAT,
			blockable = false,
			blocking = false,
			func = function()
				if state.get() and state.get().stage3_cinematic then
					PlayerHost.drop_stage3_boss()
				end
				return true
			end,
		}
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end
end
