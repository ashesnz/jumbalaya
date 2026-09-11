---@meta

---@class LetterCard
---@field id number
---@field letter string
---@field color_key string
---@field pile_id "hand"|"draw"|"pattern"|"bonus"|"discard"
---@field slot_index number|nil
---@field ability table|nil
---@field bonus_card boolean|nil
---@field boss_temp boolean|nil

---@class PileState
---@field hand LetterCard[]
---@field draw LetterCard[]
---@field pattern LetterCard[]
---@field bonus LetterCard[]
---@field discard LetterCard[]
