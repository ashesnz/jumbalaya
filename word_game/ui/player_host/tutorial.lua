
local Scheduler = require "app.effects.timeline_scheduler"
return function(ctx)
	local PlayerHost = ctx.PlayerHost
	local characters = ctx.characters
	local state = ctx.state
	local BUBBLE_ALIGN = ctx.BUBBLE_ALIGN

	function PlayerHost.show_nudge(text_key)
		PlayerHost.ensure()
		local host = G.player_host
		if not host then return end
		host.talking = false
		host:remove_speech_bubble()
		host:add_speech_bubble(text_key, BUBBLE_ALIGN)
		host:pulse(0.06, 0.04)
		play_sfx("cancel", 0.85, 0.55)
		PlayerHost.sync_spotlight(text_key)
	end

	function PlayerHost.continue_after_score()
		local rs = state.get()
		if rs then
			rs.intro_waiting_score = nil
		end
		if not rs or not rs.character_intro_active then return end

		local keys = characters.intro_step_keys()
		if not keys then
			PlayerHost.dismiss_intro()
			return
		end

		local step = (rs.character_intro_step or 1) + 1
		if step > #keys then
			PlayerHost.dismiss_intro()
			return
		end

		rs.character_intro_step = step
		PlayerHost.show_step(step)
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.advance_intro()
		local rs = state.get()
		if not rs or not rs.character_intro_active then return end
		if rs.intro_waiting_score then return end

		local keys = characters.intro_step_keys()
		if not keys then
			PlayerHost.dismiss_intro()
			return
		end

		local current_key = keys[rs.character_intro_step or 1]
		local required = characters.intro_required_word(current_key)
		if required then
			local preview = WORD_GAME and WORD_GAME.Play and WORD_GAME.Play.preview()
			if not preview or preview.word ~= required or not preview.valid then
				PlayerHost.show_nudge(characters.intro_nudge_key(current_key) or current_key)
				return
			end
			rs.intro_waiting_score = true
			PlayerHost.clear_spotlight()
			local host = G.player_host
			if host then
				host:remove_speech_bubble()
			end
			if WORD_GAME and WORD_GAME.Sidebar then
				WORD_GAME.Sidebar.sync_action_buttons()
			end
			require("word_game.ui.play_resolution").resolve(WORD_GAME.Play, {
				keep_intro = true,
				letters_only = true,
				on_complete = function()
					Scheduler.add{
						mode = "delayed",
						delay = 0.45,
						blockable = false,
						blocking = false,
						func = function()
							PlayerHost.continue_after_score()
							return true
						end,
					}
				end,
			})
			return
		end

		local step = (rs.character_intro_step or 1) + 1
		if step > #keys then
			PlayerHost.dismiss_intro()
			return
		end

		rs.character_intro_step = step
		PlayerHost.show_step(step)
	end

	function PlayerHost.maybe_intro()
		if G.STATE ~= G.STATES.TABLE_BOARD then return end
		if characters.skip_intro() then return end
		local char = characters.current()
		if not char or char.key ~= "milo" then return end
		local rs = state.get()
		if not rs or rs.milo_intro_shown then return end
		rs.milo_intro_shown = true
		rs.character_intro_step = 1

		local letters = characters.intro_hand_letters()
		if letters and WORD_GAME and WORD_GAME.Deck then
			WORD_GAME.Deck.ensure_letters_in_hand(letters)
		end

		PlayerHost.show_step(1)
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.schedule_intro(delay)
		delay = delay or 0.85
		Scheduler.add{
			mode = "delayed",
			delay = delay,
			blockable = false,
			blocking = false,
			func = function()
				PlayerHost.maybe_intro()
				return true
			end,
		}
	end
end
