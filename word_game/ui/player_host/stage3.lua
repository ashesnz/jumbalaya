
local Scheduler = require "app.effects.timeline_scheduler"
local Easing = require "app.effects.easing"

return function(ctx)
	local PlayerHost = ctx.PlayerHost
	local Layout = ctx.Layout
	local state = ctx.state
	local STAGE3_DIM_TIME = ctx.STAGE3_DIM_TIME
	local STAGE3_SLIDE_TIME = ctx.STAGE3_SLIDE_TIME
	local STAGE3_ALLY_LINES = ctx.STAGE3_ALLY_LINES

	function PlayerHost.end_stage3_cinematic()
		local rs = state.get()
		if rs then
			rs.stage3_cinematic = nil
			rs.stage3_portrait_pose = nil
			rs.stage3_portrait_rect = nil
			rs.stage3_portrait_visible = nil
			rs.stage3_slide_started = nil
			rs.stage3_boss_visible = nil
			rs.stage3_boss_portrait_rect = nil
			rs.stage3_boss_index = nil
			rs.stage3_boss_started = nil
			rs.stage3_ally_visible = nil
			rs.stage3_ally_portrait_rect = nil
			rs.stage3_ally_index = nil
			rs.stage3_ally_started = nil
			rs.stage3_ally_line = nil
			rs.stage3_guest_visible = nil
			rs.stage3_guest_portrait_rect = nil
			rs.stage3_guest_index = nil
			rs.stage3_guest_pose = nil
			rs.stage3_guest_started = nil
			rs.stage3_guest_line = nil
			rs.stage3_active_turn = nil
			rs.stage3_scoring_turn = nil
		end
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
		if G.INTRO_OVERLAY and G.INTRO_OVERLAY.spotlight_key then
			local key = G.INTRO_OVERLAY.spotlight_key
			if string.sub(key, 1, 11) == "milo_stage3" or string.sub(key, 1, 12) == "milo_stage23" then
				PlayerHost.clear_spotlight()
			end
		end
		PlayerHost.refresh_card_input()
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.begin_stage3_play()
		local rs = state.get()
		if not rs then return end
		rs.stage3_cinematic_seen = true
		rs.cinematic_seen = rs.cinematic_seen or {}
		rs.cinematic_seen["1-3"] = true
		rs.stage3_cinematic = nil
		rs.stage3_portrait_rect = nil
		rs.stage3_portrait_pose = "left"
		rs.stage3_boss_portrait_rect = nil
		rs.stage3_ally_portrait_rect = nil
		rs.stage3_ally_line = nil
		rs.stage3_ally_visible = true
		rs.stage3_ally_index = 1
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
		PlayerHost.clear_spotlight()
		PlayerHost.refresh_card_input()
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.stage3_ally_awaiting_click()
		local rs = state.get()
		if not (rs and rs.stage3_cinematic) then return false end
		return (rs.stage3_ally_line or rs.stage3_guest_line) and true or false
	end

	function PlayerHost.show_stage3_ally_line(index)
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		local key = STAGE3_ALLY_LINES[index]
		if not key then
			PlayerHost.begin_stage3_play()
			return
		end
		rs.stage3_ally_line = index
		if WORD_GAME and WORD_GAME.AllyHost then
			WORD_GAME.AllyHost.say(key)
		end
		PlayerHost.sync_spotlight("milo_stage3_ally_talk")
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.advance_stage3_ally()
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		if rs.stage3_guest_line then
			PlayerHost.show_marco_line(rs.stage3_guest_line + 1)
			return
		end
		if not rs.stage3_ally_line then return end
		PlayerHost.show_stage3_ally_line(rs.stage3_ally_line + 1)
	end

	function PlayerHost.consume_stage3_ally_click()
		if not PlayerHost.stage3_ally_awaiting_click() then return false end
		PlayerHost.advance_stage3_ally()
		return true
	end

	function PlayerHost.place_stage3_portrait(pose)
		local rs = state.get()
		if not rs then return end
		rs.stage3_portrait_rect = nil
		rs.stage3_portrait_pose = pose
		local host = G.player_host
		if host then
			host:apply_screen_position()
		end
	end

	function PlayerHost.slide_stage3_portrait(to_pose, duration)
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		duration = duration or STAGE3_SLIDE_TIME
		local from = Layout.portrait_rect()
		local dest = Layout.cinematic_pose_rect(to_pose)
		rs.stage3_portrait_rect = {
			x = from.x,
			y = from.y,
			w = from.w,
			h = from.h,
		}
		Easing.value{ref_table = rs.stage3_portrait_rect, ref_value = "x", mod = dest.x - from.x, timer = "REAL", not_blockable = true, delay = duration, ease = "quad"}
		Scheduler.add{
			mode = "delayed",
			delay = duration,
			blockable = false,
			blocking = false,
			func = function()
				if rs.stage3_cinematic then
					rs.stage3_portrait_rect = nil
					rs.stage3_portrait_pose = to_pose
					PlayerHost.reveal_stage3_portrait()
				end
				return true
			end,
		}
	end

	function PlayerHost.schedule_stage3_portrait_slide()
		Scheduler.add{
			mode = "delayed",
			delay = STAGE3_DIM_TIME + 0.05,
			blockable = false,
			blocking = false,
			func = function()
				local rs = state.get()
				if rs and rs.stage3_cinematic then
					PlayerHost.slide_stage3_portrait("left", STAGE3_SLIDE_TIME)
				end
				return true
			end,
		}
	end

	function PlayerHost.reveal_stage3_portrait()
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		rs.stage3_portrait_visible = true
		PlayerHost.ensure()
		local host = G.player_host
		if host then
			host:apply_screen_position()
		end
		PlayerHost.say("milo_stage3")
		if host then
			host:apply_screen_position()
		end
		PlayerHost.sync_spotlight("milo_stage3")
		PlayerHost.schedule_stage3_boss_drop()
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end
end
