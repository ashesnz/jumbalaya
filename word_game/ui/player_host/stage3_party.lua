
local Scheduler = require "app.effects.timeline_scheduler"
local Easing = require "app.effects.easing"

return function(ctx)
	local PlayerHost = ctx.PlayerHost
	local Layout = ctx.Layout
	local CharacterSpeech = ctx.CharacterSpeech
	local state = ctx.state
	local STAGE3_BOSS_DROP_TIME = ctx.STAGE3_BOSS_DROP_TIME
	local STAGE3_BOSS_BEAT = ctx.STAGE3_BOSS_BEAT

	function PlayerHost.drop_stage3_boss()
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		local dest = Layout.cinematic_boss_rest_rect()
		local start_y = dest.y - dest.h - math.max(1.2, G.TILE_H * 0.22)
		local wr = G.GAME and G.GAME.word_round
		rs.stage3_boss_visible = true
		rs.stage3_boss_index = 1
		rs.stage3_boss_portrait_rect = {
			x = dest.x,
			y = start_y,
			w = dest.w,
			h = dest.h,
		}
		local milo = G.player_host
		if milo then
			milo:remove_speech_bubble()
		end
		local round_config = require("word_game.config.round_config")
		local marco = wr and round_config.is_marco_cinematic_hand(wr.set, wr.hand_index)
		PlayerHost.sync_spotlight(marco and "milo_stage23_boss" or "milo_stage3_boss")
		Easing.value{ref_table = rs.stage3_boss_portrait_rect, ref_value = "y", mod = dest.y - start_y, timer = "REAL", not_blockable = true, delay = STAGE3_BOSS_DROP_TIME, ease = "quad"}
		Scheduler.add{
			mode = "delayed",
			delay = STAGE3_BOSS_DROP_TIME,
			blockable = false,
			blocking = false,
			func = function()
				if not rs.stage3_cinematic then return true end
				rs.stage3_boss_portrait_rect = nil
				local wr = G.GAME and G.GAME.word_round
				local round_config = require("word_game.config.round_config")
				local marco = wr and round_config.is_marco_cinematic_hand(wr.set, wr.hand_index)
				if marco then
					PlayerHost.sync_spotlight("milo_stage23_boss_talk")
					PlayerHost.schedule_marco_drop()
				else
					PlayerHost.sync_spotlight("milo_stage3_boss_talk")
					PlayerHost.schedule_stage3_ally_drop()
				end
				return true
			end,
		}
	end

	function PlayerHost.schedule_stage3_boss_drop()
		local rs = state.get()
		if not rs or rs.stage3_boss_started then return end
		rs.stage3_boss_started = true
		local wait = CharacterSpeech.duration("milo_stage3") + STAGE3_BOSS_BEAT
		Scheduler.add{
			mode = "delayed",
			delay = wait,
			blockable = false,
			blocking = false,
			func = function()
				if state.get() and state.get().stage3_cinematic then
					PlayerHost.drop_stage3_boss()
				end
				return true
			end,
		}
	end

	function PlayerHost.schedule_stage3_ally_drop()
		local rs = state.get()
		if not rs or rs.stage3_ally_started then return end
		rs.stage3_ally_started = true
		local wait = CharacterSpeech.duration("boss_stage3_intro") + STAGE3_BOSS_BEAT
		Scheduler.add{
			mode = "delayed",
			delay = wait,
			blockable = false,
			blocking = false,
			func = function()
				if state.get() and state.get().stage3_cinematic then
					PlayerHost.drop_stage3_ally()
				end
				return true
			end,
		}
	end

	function PlayerHost.drop_stage3_ally()
		local rs = state.get()
		if not rs or not rs.stage3_cinematic then return end
		local dest = Layout.cinematic_ally_rest_rect()
		local start_y = dest.y - dest.h - math.max(1.2, G.TILE_H * 0.22)
		rs.stage3_ally_visible = true
		rs.stage3_ally_index = 1
		rs.stage3_ally_portrait_rect = {
			x = dest.x,
			y = start_y,
			w = dest.w,
			h = dest.h,
		}
		PlayerHost.sync_spotlight("milo_stage3_ally")
		if WORD_GAME and WORD_GAME.AllyHost then
			WORD_GAME.AllyHost.ensure()
		end
		Easing.value{ref_table = rs.stage3_ally_portrait_rect, ref_value = "y", mod = dest.y - start_y, timer = "REAL", not_blockable = true, delay = STAGE3_BOSS_DROP_TIME, ease = "quad"}
		Scheduler.add{
			mode = "delayed",
			delay = STAGE3_BOSS_DROP_TIME,
			blockable = false,
			blocking = false,
			func = function()
				if not rs.stage3_cinematic then return true end
				rs.stage3_ally_portrait_rect = nil
				PlayerHost.show_stage3_ally_line(1)
				return true
			end,
		}
	end

	function PlayerHost.reset_stage3_cinematic_state()
		local rs = state.get()
		if not rs then return end
		rs.stage3_portrait_pose = "center"
		rs.stage3_portrait_visible = false
		rs.stage3_portrait_rect = nil
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
end
