--[[ packages/jumbalaya_core/jumble/placement_preview.lua - Placement row preview (no G) ]]

local ModifierEffects = require("jumbalaya_core.rules.letter_modifier_effects")

local M = {}

function M.preview_word(slots, opts)
	opts = opts or {}
	if not slots or (opts.placed_count or 0) <= 0 then return nil end
	local build_word = opts.build_word
	if not build_word then return nil end
	local word = build_word(slots)
	if not word or word == "" then return nil end
	local used_cards = opts.collect_used_cards and opts.collect_used_cards(slots)
	word = ModifierEffects.adjust_word_for_q(word, used_cards)
	if word == "" then return nil end
	for _, played in ipairs(opts.puzzle_words or {}) do
		if played == word then return nil end
	end
	return word, used_cards
end

function M.validate_preview(word, opts)
	opts = opts or {}
	if not word or word == "" then return false end
	if opts.is_valid_word and not opts.is_valid_word(word) then return false end
	if opts.is_word_played and opts.is_word_played(word) then return false end
	return true
end

function M.placement_preview_got(j, rules, score_opts)
	if not j or not rules then return 0 end
	local word, used_cards = M.preview_word(j.slots, {
		placed_count = rules.placed_count(j.slots),
		build_word = rules.build_placement_preview_word,
		collect_used_cards = rules.collect_used_cards,
		puzzle_words = j.puzzle_words,
	})
	if not word then return 0 end
	local committed_puzzle = rules.puzzle_total(j)
	local preview = rules.preview_puzzle_total_after_word(j, word, used_cards, score_opts)
	return math.max(0, preview - committed_puzzle)
end

return M
