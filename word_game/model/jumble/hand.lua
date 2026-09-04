--[[ word_game/model/jumble/hand.lua - Jumble hand lifecycle, timer, and puzzle progression ]]

return function(M)
local TIMER_ENABLED = false
local TIMER_SECONDS = 30
local modifier_effects = require("word_game.model.jumble_play.letter_modifier_effects")
local bonus_stack = require("word_game.ui.boss_word_stack")
local round_config = require("word_game.config.round_config")
local jumble_rules = require("word_game.model.jumble_play.jumble_rules")

function M.is_active_hand(set, hand_index)
	set = set or (G.GAME and G.GAME.word_round and G.GAME.word_round.set) or 1
	hand_index = hand_index or (G.GAME and G.GAME.word_round and G.GAME.word_round.hand_index) or 1
	return set >= 1 and set <= round_config.SETS_TO_WIN and hand_index >= 1
		and hand_index <= round_config.hands_in_set(set)
end

function M.is_active()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.mode == "jumble" and wr.jumble ~= nil
end

function M.state()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.jumble
end

function M.apply_puzzle(wr, puzzle)
	local j = wr.jumble
	if not j or not puzzle then return end
	puzzle = M.resolve_puzzle(puzzle)
	j.puzzle = puzzle
	j.pattern = M.display_pattern(puzzle)
	j.solved = false
	j.bonus_available = false
	j.bonus_card_id = nil
	j.puzzle_points = 0
	j.puzzle_multi = 1.0
	j.puzzle_words = {}
	j.slots = M.parse_slots(puzzle)
	modifier_effects.reset_puzzle_state(j)

	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.reset_puzzle_smoke then
		WORD_GAME.TimelineTimer.reset_puzzle_smoke()
	end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.sync_progress then
		WORD_GAME.TimelineTimer.sync_progress()
	end

	if WORD_GAME and WORD_GAME.ScoreBanner and WORD_GAME.ScoreBanner.reset_jumble_score then
		WORD_GAME.ScoreBanner.reset_jumble_score()
	end

	local area = G.placement_table and G.placement_table.area
	if area and area.cards then
		for i = #area.cards, 1, -1 do
			local card = area.cards[i]
			if G.placement_table then
				G.placement_table:on_remove_card(card)
			end
			area:remove_card(card)
			if card.bonus_card then
				bonus_stack.return_card(card)
			elseif card.area ~= G.hand and G.hand then
				G.hand:emplace(card)
			end
		end
		if area.config then
			area.config.card_limit = M.blank_count(j.slots, puzzle)
		end
		if G.placement_table then
			G.placement_table:relayout()
			if area.hard_set_cards then
				area:hard_set_cards()
			end
		end
	end

	local placement_word = require("word_game.model.placement_word")
	placement_word.clear()
end

function M.load_puzzle(wr, index)
	local set = wr and wr.set
	local hand = wr and wr.hand_index
	local list = M.puzzles(set, hand)
	if #list == 0 then return end
	local j = wr.jumble
	j.puzzle_index = ((index - 1) % #list) + 1
	M.apply_puzzle(wr, list[j.puzzle_index])
end

function M.start_hand(wr)
	wr.mode = "jumble"
	wr.target = wr.target or 20
	modifier_effects.reset_stage_state(wr)
	local alpha = G.GAME and G.GAME.alpha
	if alpha then
		alpha.character_intro_active = false
		alpha.intro_waiting_score = false
	end

	wr.jumble = {
		total_score = 0,
		puzzle_index = 1,
		solved = false,
		bonus_available = false,
		bonus_card_id = nil,
		puzzle_points = 0,
		puzzle_multi = 1.0,
		puzzle_words = {},
		boss_word_active = false,
		deadline = TIMER_ENABLED and ((G.TIMERS and G.TIMERS.REAL or 0) + TIMER_SECONDS) or nil,
		time_left = TIMER_ENABLED and TIMER_SECONDS or nil,
	}

	if WORD_GAME and WORD_GAME.ScoreBanner then
		local hud = WORD_GAME.ScoreBanner.state()
		hud.to_go_label = "SCORE"
		hud.target = 0
		hud.remaining = 0
		if WORD_GAME.ScoreBanner.reset_jumble_score then
			WORD_GAME.ScoreBanner.reset_jumble_score()
		end
	end

	M.load_puzzle(wr, 1)
end

function M.start_boss_word(wr)
	return M.reveal_boss_puzzle(wr)
end

function M.prepare_boss_word(wr)
	if not wr or not round_config.is_boss_word_hand(wr.set, wr.hand_index) or not wr.jumble then return false end
	local boss = M.boss_puzzle(wr.set, wr.hand_index)
	if not boss then return false end
	wr.jumble.pending_boss = boss
	wr.jumble.boss_puzzle_hidden = true
	wr.jumble.boss_word_active = false
	if wr.jumble.slots then
		M.clear_blank_cards(wr.jumble.slots)
		M.sync_placement_cards(wr.jumble.slots)
	end
	wr.jumble.slots = nil
	wr.jumble.pattern = nil
	return true
end

function M.reveal_boss_puzzle(wr)
	if not wr or not round_config.is_boss_word_hand(wr.set, wr.hand_index) or not wr.jumble then return false end
	local boss = wr.jumble.pending_boss
	if not boss then return false end
	wr.jumble.pending_boss = nil
	wr.jumble.boss_puzzle_hidden = false
	wr.jumble.boss_word_active = true
	wr.jumble.puzzle_phase_complete = true
	wr.jumble.solved = false
	wr.jumble.puzzle_points = 0
	wr.jumble.puzzle_multi = 1.0
	wr.jumble.puzzle_words = {}
	M.apply_puzzle(wr, boss)
	if WORD_GAME and WORD_GAME.Layout and WORD_GAME.Layout.refresh_placement_layout then
		WORD_GAME.Layout.refresh_placement_layout()
	elseif G.placement_table and G.placement_table.apply_screen_position then
		G.placement_table:apply_screen_position()
	end
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_visibility then
		WORD_GAME.Sidebar.sync_visibility()
	end
	if WORD_GAME and WORD_GAME.HandShuffle and WORD_GAME.HandShuffle.sync_position then
		WORD_GAME.HandShuffle.sync_position()
	end
	if WORD_GAME and WORD_GAME.ScoreBanner and WORD_GAME.ScoreBanner.set_banner_mode then
		WORD_GAME.ScoreBanner.set_banner_mode("boss_word", "BOSS WORD")
	end
	if WORD_GAME and WORD_GAME.ScoreBanner and WORD_GAME.ScoreBanner.hide_points_to_get_display then
		WORD_GAME.ScoreBanner.hide_points_to_get_display()
	end
	return true
end

function M.begin_boss_word(wr, on_complete)
	if not wr or not wr.jumble or wr.jumble.boss_word_active then return false end
	wr.jumble.boss_word_staging = true
	if WORD_GAME and WORD_GAME.PlayEffects and WORD_GAME.PlayEffects.present_boss_word then
		WORD_GAME.PlayEffects.present_boss_word(wr, on_complete)
		return true
	end
	if M.prepare_boss_word(wr) and WORD_GAME and WORD_GAME.Deck then
		local letters = M.boss_hand_letters(
			wr.jumble.pending_boss.boss_word,
			wr.jumble.pending_boss.pattern
		)
		WORD_GAME.Deck.deal_boss_hand(letters, on_complete)
		return true
	end
	return false
end

function M.current_puzzle_points()
	local j = M.state()
	return j and j.puzzle_points or 0
end

function M.current_puzzle_multi()
	local j = M.state()
	return j and j.puzzle_multi or 1.0
end

function M.record_puzzle_word(word, opts)
	opts = opts or {}
	local j = M.state()
	if not j then return 0, 0, 1.0, 1.0 end
	local wr = G.GAME and G.GAME.word_round
	local used_cards = opts.used_cards
	local old_pts = j.puzzle_points or 0
	local old_multi = j.puzzle_multi or 1.0

	local effects = modifier_effects.apply_word_effects(word, used_cards, j, wr)
	local word_pts = #word + (effects.bonus_points or 0)
	word_pts = word_pts + bonus_stack.bonus_points_for(used_cards)
	local committed = jumble_rules.committed_before_word(j, old_pts, old_multi)
	word_pts = jumble_rules.scale_post_target_points(j, word_pts, committed)
	local new_pts = old_pts + word_pts
	j.puzzle_words = j.puzzle_words or {}
	table.insert(j.puzzle_words, word)
	local count = #j.puzzle_words
	local new_multi = 1.0
	if count >= 2 then
		new_multi = 1.0 + (count - 1) * 0.2
		new_multi = math.floor(new_multi * 10 + 0.5) / 10
	end
	new_multi = modifier_effects.apply_next_word_floor(new_multi, j)
	new_multi = modifier_effects.apply_combo_bonus(new_multi, effects.combo_bonus)
	new_multi = math.floor((new_multi + (effects.bonus_multi or 0)) * 10 + 0.5) / 10

	j.puzzle_points = new_pts
	j.puzzle_multi = new_multi
	j.solved = true
	return old_pts, new_pts, old_multi, new_multi
end

function M.time_left()
	if not TIMER_ENABLED then return math.huge end
	local j = M.state()
	if not j or not j.deadline then return 0 end
	return math.max(0, j.deadline - (G.TIMERS.REAL or 0))
end

function M.update_timer()
	if not TIMER_ENABLED then return false end
	local j = M.state()
	if not j then return false end
	j.time_left = math.ceil(M.time_left())
	if j.time_left <= 0 then
		return true
	end
	return false
end

function M.refresh_hud()
	if not M.is_active() then return end
	local j = M.state()
	if WORD_GAME and WORD_GAME.ScoreBanner then
		local hud = WORD_GAME.ScoreBanner.state()
		hud.to_go_label = "SCORE"
		hud.remaining = j.total_score or 0
		if WORD_GAME.ScoreBanner.sync_points_to_get_preview then
			WORD_GAME.ScoreBanner.sync_points_to_get_preview(false)
		end
	end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.sync_progress then
		WORD_GAME.TimelineTimer.sync_progress()
	end
end

function M.advance_puzzle(wr)
	if not wr or not wr.jumble then return end
	M.load_puzzle(wr, wr.jumble.puzzle_index + 1)
end
end
