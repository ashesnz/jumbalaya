--[[
	types/store.lua - Run snapshot and store state (analyzer-only).

	Authoritative run schema for Game.GAME / WORD_GAME.store() lives here.
	Engine shell types remain in types/game.lua.
]]

---@meta

---@class RunState
---@field tokens number
---@field perks table
---@field perk_slots number
---@field stats table
---@field trade_used_this_hand boolean
---@field match_over boolean
---@field match_won boolean
---@field [string] any

---@class JumbleSlot
---@field kind string
---@field letter string|nil
---@field cards table[]|nil
---@field min number|nil
---@field max number|nil

---@class JumbleState
---@field total_score number
---@field puzzle_index number|nil
---@field solved boolean
---@field bonus_available boolean|nil
---@field bonus_card_id string|nil
---@field puzzle_points number
---@field puzzle_multi number
---@field puzzle_words string[]
---@field puzzle table|nil
---@field pattern string|nil
---@field slots JumbleSlot[]|nil
---@field boss_word_active boolean|nil
---@field boss_word_staging boolean|nil
---@field boss_puzzle_hidden boolean|nil
---@field pending_boss table|nil
---@field boss_cards Card[]|nil
---@field locked_hand_layout table|nil

---@class WordRound
---@field set number
---@field hand_index number
---@field target number
---@field played_words table<string, boolean>|string[]
---@field mode string|nil
---@field hand_name string|nil
---@field jumble JumbleState|nil
---@field [string] any

---@class GameRunState
--- Run-wide fields on Game.GAME / store snapshot. Each group has a single owning module.
---
--- Owner: model/game/run.lua, model/run/scope.lua
---@field run_mode "classic"|"time_run"|string|nil
---@field run_generation number|nil
---@field run_state RunState|nil
---@field won boolean|nil
---@field seeded boolean|nil
---@field pseudorandom table|nil
---@field seed_streams { seed: string, hashed_seed: number }|nil
---@field starting_deck_size number|nil
---@field starting_params { hand_size: number, usable_slots: number|nil }|nil
---@field points number|nil
---@field round number|nil
---@field round_scores table<string, { amt: number }>|nil
---@field modifiers table<string, boolean>|nil
---@field deck_alpha { pos: { x: number, y: number } }|nil
---@field deck_left_count number|nil
---
--- Owner: model/round/init.lua (+ jumble/hand.lua for wr.jumble)
---@field word_round WordRound|nil
---
--- Owner: model/run/timeline.lua (Time Run fuse; classic goal/target reads)
---@field timeline_seconds number|nil
---@field timeline_duration number|nil
---@field timeline_active boolean|nil
---@field timeline_frozen boolean|nil
---@field timeline_boss_override boolean|nil
--- Owner: model/run/timeline.lua (fuse); classic mirror writes via ui/perks/timeline_timer
---@field timeline_goal_reached boolean|nil
---@field timeline_progress_target number|nil
---
--- Owner: model/jumble/placement_word.lua
---@field placement_word string|nil
---@field placement_word_valid boolean|nil
---
--- Owner: model/perks/voucher_discard.lua (+ round reset)
---@field voucher_discards_used number|nil
---@field discard_bin_count number|nil
---
--- Owner: model/perks/registry.lua
---@field selected_perk string|nil
---
--- Owner: model/jumble_play/* and ui/table/controls/* (InputLock reads)
---@field word_score_animating boolean|nil
---@field hand_shuffle_animating boolean|nil
---@field hand_redraw_animating boolean|nil
---@field placement_recall_animating boolean|nil
---
--- Owner: model/run/busy.lua (FX modules push on animation start/end)
---@field trade_ui_busy boolean|nil
---@field token_reward_busy boolean|nil
---@field card_fly_off_busy boolean|nil
---@field play_hold_redraw_busy boolean|nil
---
--- Owner: ui/table/controls/animate.lua
---@field hand_layout_settle number|nil
---
--- Owner: ui/perks/stamp/*
---@field pending_stamp_perk table|nil
---
--- Owner: ui/cards/inspect.lua
---@field inspecting_card Card|nil
---
--- Owner: app/input/actions.lua, app/callbacks/controllers/run_lifecycle.lua
---@field viewed_back any|nil
---@field [string] any

---@class PileState
---@field hand table[]
---@field draw table[]
---@field pattern table[]
---@field bonus table[]
---@field discard table[]

---@class GameStoreState : GameRunState
---@field word_round WordRound
---@field piles PileState
---@field shuffle_hand_count number|nil
---@field last_gameplay_action string|nil
---@field last_trade_action string|nil

---@class GameStore
local GameStore = {}
function GameStore:get() end
function GameStore:dispatch(action) end
function GameStore:patch(patch) end
function GameStore:replace(state) end
function GameStore:subscribe(fn) end
