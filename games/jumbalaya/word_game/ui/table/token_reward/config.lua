--[[ word_game/ui/table/token_reward/config.lua - Fly animation tuning ]]

local M = {}

M.STICKER_CELL = { x = 0, y = 0 }
M.FLY_DUR = 0.52
M.STAGGER = 0.042
M.ARC = 42
M.MAX_REWARD_FLYERS = 12

-- Classic hand-end: banked score ticks down on the fuse bar (1 point per step).
M.SCORE_ROLL_MIN = 0.55
M.SCORE_ROLL_MAX = 2.8
M.SCORE_ROLL_SEC_PER_POINT = 0.018

return M
