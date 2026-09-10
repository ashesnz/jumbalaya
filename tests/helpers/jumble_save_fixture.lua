--[[ tests/helpers/jumble_save_fixture.lua - Minimal on-disk jumble hand snapshot for save tests ]]

local M = {}

--- GAME blob with an active jumble hand (set 2, hand 1).
function M.game_snapshot()
	return {
		run_mode = "time_run",
		run_state = {
			tokens = 12,
			perks = {},
			trade_used_this_hand = false,
		},
		timeline_seconds = 42,
		timeline_duration = 60,
		timeline_active = true,
		word_round = {
			set = 2,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 18,
				puzzle_index = 1,
				solved = false,
				puzzle_points = 3,
				puzzle_multi = 1.0,
				puzzle_words = { "CAT" },
				boss_word_active = false,
			},
		},
	}
end

--- Write a compressed save and return the path (caller removes).
function M.write_temp(path, write_save_file, hand_card_save)
	path = path or "test_jumble_hand_save.acs"
	local snapshot = {
		VERSION = "test",
		STATE = G.STATES and G.STATES.TABLE_BOARD or 1,
		GAME = M.game_snapshot(),
		cardAreas = {
			hand = {
				config = { type = "hand", card_limit = 7 },
				cards = { hand_card_save },
			},
		},
	}
	write_save_file(path, snapshot)
	return path
end

--- Load path → unpacked table (does not mutate G).
function M.read_temp(path, read_save_payload, unpack_source)
	local source = read_save_payload(path)
	if not source then return nil end
	return unpack_source(source)
end

--- Apply unpacked save onto live G (card areas + round restore).
function M.apply_loaded(loaded, restore_card_areas, round_restore)
	G.GAME = loaded.GAME
	G.STATE = loaded.STATE
	if restore_card_areas then
		restore_card_areas(loaded)
	end
	if round_restore then
		round_restore()
	end
end

return M
