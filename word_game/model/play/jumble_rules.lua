--[[ word_game/model/play/jumble_rules.lua - Pure jumble play logic (no UI) ]]

local M = {}

local round = require("word_game.model.round")
local modifier_effects = require("word_game.model.play.letter_modifier_effects")

function M.placed_count(slots)
	local count = 0
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and slot.card then
			count = count + 1
		elseif slot.kind == "span" and slot.cards then
			count = count + #slot.cards
		end
	end
	return count
end

function M.collect_used_cards(slots)
	local used = {}
	for _, slot in ipairs(slots or {}) do
		if slot.kind == "blank" and slot.card then
			used[#used + 1] = slot.card
		elseif slot.kind == "span" then
			for _, card in ipairs(slot.cards or {}) do
				used[#used + 1] = card
			end
		end
	end
	return used
end

function M.round_target()
	return (G.GAME and G.GAME.word_round and G.GAME.word_round.target) or 20
end

function M.score_remaining(total_score, target)
	return math.max(0, target - total_score)
end

function M.puzzle_total(j)
	local pts = j.puzzle_points or 0
	local multi = j.puzzle_multi or 1.0
	return math.floor(pts * multi)
end

function M.total_with_puzzle(j, pts, multi)
	return (j.total_score or 0) + math.floor(pts * multi)
end

function M.word_points(pts, multi)
	return math.floor(pts * multi)
end

function M.play_blocked(j)
	if not j then return true end
	if G.GAME and G.GAME.word_score_animating then return true end
	return false
end

function M.can_jumble_next(jumble)
	if not jumble or not jumble.is_active() then return false end
	local wr = G.GAME and G.GAME.word_round
	local j = jumble.state()
	if not wr or not j or not j.solved then return false end
	if G.GAME and G.GAME.word_score_animating then return false end
	return true
end

function M.evaluate_play(jumble, j)
	if M.play_blocked(j) then return nil end

	local placed = M.placed_count(j.slots)

	if placed == 0 and j.solved then
		local target = M.round_target()
		local bank_bonus = modifier_effects.bank_bonus_points(j)
		if bank_bonus > 0 then
			j.puzzle_points = (j.puzzle_points or 0) + bank_bonus
		end
		local puzzle_total = M.puzzle_total(j)
		local old_total = j.total_score or 0
		local new_total = old_total + puzzle_total
		j.total_score = new_total
		local old_rem = M.score_remaining(old_total, target)
		local new_rem = M.score_remaining(new_total, target)
		local puzzle_label = (j.puzzle and (j.puzzle.display or j.puzzle.pattern)) or "Puzzle"
		return {
			kind = "bank_puzzle",
			puzzle_total = puzzle_total,
			old_total = old_total,
			new_total = new_total,
			old_rem = old_rem,
			new_rem = new_rem,
			cleared = new_rem <= 0,
			puzzle_label = puzzle_label,
		}
	end

	local word, err = jumble.validate_current()
	if not word then
		return { kind = "invalid", err = err }
	end

	local used_cards = M.collect_used_cards(j.slots)
	local old_pts, new_pts, old_multi, new_multi = jumble.record_puzzle_word(word, { used_cards = used_cards })
	round.record_word_play(word)
	j.bonus_available = false
	j.bonus_card_id = nil

	local target = M.round_target()
	local old_score = M.total_with_puzzle(j, old_pts, old_multi)
	local new_score = M.total_with_puzzle(j, new_pts, new_multi)
	local v_bonus = modifier_effects.target_hit_bonus(word, used_cards, old_score, new_score, target)
	if v_bonus > 0 then
		j.puzzle_points = new_pts + v_bonus
		new_pts = j.puzzle_points
		new_score = M.total_with_puzzle(j, new_pts, new_multi)
	end
	local old_rem = M.score_remaining(old_score, target)
	local new_rem = M.score_remaining(new_score, target)
	local word_pts = M.word_points(new_pts, new_multi)

	return {
		kind = "word_play",
		word = word,
		old_pts = old_pts,
		new_pts = new_pts,
		old_multi = old_multi,
		new_multi = new_multi,
		old_score = old_score,
		new_score = new_score,
		old_rem = old_rem,
		new_rem = new_rem,
		word_pts = word_pts,
		cleared = new_rem <= 0,
		used_cards = used_cards,
	}
end

return M
