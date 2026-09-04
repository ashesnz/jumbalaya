
local Scheduler = require "app.effects.scheduler"
return function(ctx)
	local PlayerHost = ctx.PlayerHost
	local characters = ctx.characters
	local state = ctx.state
	local BUBBLE_ALIGN = ctx.BUBBLE_ALIGN

	-- function PlayerHost.maybe_stage3_cinematic()
	-- 	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	-- 	local wr = G.GAME and G.GAME.word_round
	-- 	if not wr then return end
	-- 	local round_config = require("word_game.config.round_config")
	-- 	if round_config.is_marco_cinematic_hand(wr.set, wr.hand_index) then
	-- 		PlayerHost.maybe_marco_cinematic()
	-- 		return
	-- 	end
	-- 	if not round_config.is_stage3_cinematic_hand(wr.set, wr.hand_index) then return end
	-- 	local alpha = state.get()
	-- 	if not alpha then return end
	-- 	if alpha.stage3_cinematic_seen then return end
	-- 	if alpha.stage3_cinematic then return end
	--
	-- 	PlayerHost.reset_stage3_cinematic_state()
	-- 	alpha.stage3_cinematic = true
	-- 	PlayerHost.ensure()
	-- 	local host = G.player_host
	-- 	if host then
	-- 		host:remove_speech_bubble()
	-- 		host:apply_screen_position()
	-- 	end
	-- 	PlayerHost.sync_spotlight("milo_stage3_dim")
	-- 	if not alpha.stage3_slide_started then
	-- 		alpha.stage3_slide_started = true
	-- 		PlayerHost.schedule_stage3_portrait_slide()
	-- 	end
	-- 	if WORD_GAME and WORD_GAME.Sidebar then
	-- 		WORD_GAME.Sidebar.sync_action_buttons()
	-- 	end
	-- end

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
		local alpha = state.get()
		if alpha then
			alpha.intro_waiting_score = nil
		end
		if not alpha or not alpha.character_intro_active then return end

		local keys = characters.intro_step_keys()
		if not keys then
			PlayerHost.dismiss_intro()
			return
		end

		local step = (alpha.character_intro_step or 1) + 1
		if step > #keys then
			PlayerHost.dismiss_intro()
			return
		end

		alpha.character_intro_step = step
		PlayerHost.show_step(step)
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar.sync_action_buttons()
		end
	end

	function PlayerHost.advance_intro()
		local alpha = state.get()
		if not alpha or not alpha.character_intro_active then return end
		if alpha.intro_waiting_score then return end

		local keys = characters.intro_step_keys()
		if not keys then
			PlayerHost.dismiss_intro()
			return
		end

		local current_key = keys[alpha.character_intro_step or 1]
		local required = characters.intro_required_word(current_key)
		if required then
			local preview = WORD_GAME and WORD_GAME.Play and WORD_GAME.Play.preview()
			if not preview or preview.word ~= required or not preview.valid then
				PlayerHost.show_nudge(characters.intro_nudge_key(current_key) or current_key)
				return
			end
			alpha.intro_waiting_score = true
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

		local step = (alpha.character_intro_step or 1) + 1
		if step > #keys then
			PlayerHost.dismiss_intro()
			return
		end

		alpha.character_intro_step = step
		PlayerHost.show_step(step)
	end

	function PlayerHost.maybe_intro()
		if G.STATE ~= G.STATES.TABLE_BOARD then return end
		if characters.skip_intro() then return end
		local char = characters.current()
		if not char or char.key ~= "milo" then return end
		local alpha = state.get()
		if not alpha or alpha.milo_intro_shown then return end
		alpha.milo_intro_shown = true
		alpha.character_intro_step = 1

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
