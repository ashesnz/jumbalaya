local Easing = require "app.effects.easing"
local InputLock = require("word_game.model.input_lock")

return function(ctx)
	local PlayerHost = ctx.PlayerHost
	local characters = ctx.characters
	local state = ctx.state
	local BUBBLE_ALIGN = ctx.BUBBLE_ALIGN

	function PlayerHost.refresh_card_input()
		if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
		if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
			G.placement_table.area:set_ranks()
		end
	end

	function PlayerHost.clear_spotlight()
		if G.INTRO_OVERLAY then
			G.INTRO_OVERLAY:remove()
			G.INTRO_OVERLAY = nil
		end
		G.under_overlay = false
		PlayerHost.refresh_card_input()
	end

	function PlayerHost.ensure_spotlight()
		if G.INTRO_OVERLAY or not G.ROOM_ATTACH then return end
		local overlay_colour = { 0.32, 0.36, 0.41, 0 }
		Easing.value{ref_table = overlay_colour, ref_value = 4, mod = 0.7, timer = "REAL", not_blockable = true, delay = 0.4}
		G.INTRO_OVERLAY = LayoutView{
			definition = {
				n = G.UI.ROOT,
				config = { align = "cm", padding = 32.05, r = 0.1, colour = overlay_colour, emboss = 0.05 },
				nodes = {
					{ n = G.UI.ROW, config = { align = "cm", minh = G.ROOM.T.h, minw = G.ROOM.T.w }, nodes = {} },
				},
			},
			config = {
				align = "cm",
				offset = { x = 0, y = 3.2 },
				major = G.ROOM_ATTACH,
				bond = "Weak",
			},
		}
	end

	function PlayerHost.refresh_spotlight_highlights(parts)
		if not G.INTRO_OVERLAY then return end
		local want = {}
		for _, part in ipairs(parts or {}) do
			want[part] = true
		end
		local selections = {}
		if want.hand and G.hand then
			selections[#selections + 1] = G.hand
		end
		if want.placement then
			local area = G.placement_table and G.placement_table.area
			if area then
				selections[#selections + 1] = area
			end
			local preview = G.placement_validate_ui or (G.placement_table and G.placement_table.validate_ui)
			if preview then
				selections[#selections + 1] = preview
			end
		end
		if want.next then
			local next_btn = WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.play_button_uie()
			if next_btn then
				next_btn.under_overlay = false
				selections[#selections + 1] = next_btn
			end
		end
		if want.speech then
			local host = G.player_host
			if host then
				selections[#selections + 1] = host
			end
		end
		if want.ally_speech then
			local host = G.ally_host
			if host then
				selections[#selections + 1] = host
			end
		end
		if want.guest_speech then
			local host = G.guest_host
			if host then
				selections[#selections + 1] = host
			end
		end
		G.INTRO_OVERLAY.selections = selections
		G.INTRO_OVERLAY.redraw_portrait = want.portrait and true or nil
		G.INTRO_OVERLAY.redraw_boss = want.boss and true or nil
		G.INTRO_OVERLAY.redraw_ally = want.ally and true or nil
		G.INTRO_OVERLAY.redraw_guest = want.guest and true or nil
		G.INTRO_OVERLAY.redraw_banner = want.banner and true or nil
	end

	function PlayerHost.current_intro_key()
		local alpha = state.get()
		if not alpha or not alpha.character_intro_active then
			return nil
		end
		local keys = characters.intro_step_keys()
		return keys and keys[alpha.character_intro_step or 1]
	end

	function PlayerHost.allows_card_drag(area)
		if InputLock.is_table_busy() then
			return false
		end
		if WORD_GAME and WORD_GAME.HandClearFocus and WORD_GAME.HandClearFocus.is_active() then
			return false
		end
		local alpha = state.get()
		if alpha and (alpha.intro_waiting_score or alpha.stage3_cinematic) then
			return false
		end
		local key = PlayerHost.current_intro_key()
			or (G.INTRO_OVERLAY and G.INTRO_OVERLAY.spotlight_key)
		if not key then
			return true
		end
		if characters.intro_is_free_play(key) then
			return true
		end
		if characters.intro_locks_cards(key) then
			return false
		end
		if not G.INTRO_OVERLAY or not G.INTRO_OVERLAY.spotlight_parts then
			return true
		end
		for _, part in ipairs(G.INTRO_OVERLAY.spotlight_parts) do
			if part == "hand" and area == G.hand then
				return true
			end
			if part == "placement" and G.placement_table and area == G.placement_table.area then
				return true
			end
		end
		return false
	end

	function PlayerHost.sync_spotlight(step_or_key)
		local key = step_or_key
		if type(step_or_key) == "number" then
			local keys = characters.intro_step_keys()
			key = keys and keys[step_or_key]
		end
		local parts = characters.intro_spotlight(key)
		if not parts or characters.intro_is_free_play(key) then
			PlayerHost.clear_spotlight()
			return
		end
		PlayerHost.ensure_spotlight()
		G.INTRO_OVERLAY.spotlight_key = key
		G.INTRO_OVERLAY.spotlight_parts = parts
		PlayerHost.refresh_spotlight_highlights(parts)
		PlayerHost.refresh_card_input()
	end

	function PlayerHost.dismiss_intro()
		local host = G.player_host
		if host then
			host.talking = false
			host:remove_speech_bubble()
		end
		PlayerHost.clear_spotlight()
		local alpha = state.get()
		if alpha then
			alpha.character_intro_active = false
			alpha.character_intro_step = nil
			alpha.intro_waiting_score = nil
		end
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.show_step(step)
		local keys = characters.intro_step_keys()
		if not keys or not keys[step] then
			PlayerHost.dismiss_intro()
			return
		end

		PlayerHost.ensure()
		local host = G.player_host
		host.talking = false
		host:remove_speech_bubble()
		host:add_speech_bubble(keys[step], BUBBLE_ALIGN)
		host:pulse(0.04, 0.02)
		PlayerHost.sync_spotlight(step)
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.say(text_key, loc_vars)
		PlayerHost.ensure()
		local host = G.player_host
		if not host or not host.states.visible then return end
		host.talking = false
		host:remove_speech_bubble()
		host:add_speech_bubble(text_key, BUBBLE_ALIGN, loc_vars)
		host:pulse(0.06, 0.04)
	end
end
