--[[ word_game/ui/letter_tile.lua - Letter tile UI components for word history ]]

local LetterFaces = require "word_game.ui.letter_card_faces"
local Palette = require "word_game.config.letter_card_palette"

local LetterTile = {}

function LetterTile.snapshot_from_card(card)
    local letter = (card.ability and card.ability.letter)
        or (Dictionary and Dictionary.letter_from_card(card))
        or "?"
    local color = (card.ability and card.ability.letter_color)
        or (Dictionary and Dictionary.color_from_card(card))
        or "black"

    local pos = nil
    if card.config and card.config.card and card.config.card.pos then
        pos = card.config.card.pos
    elseif card.children and card.children.front and card.children.front.pos then
        pos = card.children.front.pos
    end
    pos = pos or LetterFaces.glyph_pos(letter)

    return {
        letter = letter,
        letter_color = color,
        pos = pos,
    }
end

function LetterTile.snapshot_cards(cards)
    local out = {}
    if not cards then return out end
    for _, card in ipairs(cards) do
        out[#out + 1] = LetterTile.snapshot_from_card(card)
    end
    return out
end

-- Renders a single letter/card image
function LetterTile.ui_node(snap, scale)
    local palette = Palette.scheme()
    local fill = palette[snap.letter_color] or palette.black
    local tile_w = 0.52 * scale
    local tile_h = 0.68 * scale

    local tile_content
    local letters_atlas = LetterFaces.letters_atlas()
    if letters_atlas and snap.pos then
        local sprite = Sprite(0, 0, tile_w, tile_h, letters_atlas, snap.pos)
        sprite.states.drag.can = false
        sprite.states.hover.can = false
        sprite.states.collide.can = false
        tile_content = { n = G.UI.OBJECT, config = { object = sprite } }
    else
        tile_content = { n = G.UI.TEXT, config = {
            text = snap.letter or "?",
            scale = 0.48 * scale,
            colour = { 1, 1, 1, 1 },
            shadow = true,
        }}
    end

    return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.008, maxw = tile_w + 0.02 }, nodes = {
        { n = G.UI.ROW, config = { align = "cm" }, nodes = {
            { n = G.UI.COLUMN, config = {
                align = "cm",
                minw = tile_w,
                maxw = tile_w,
                minh = tile_h,
                maxh = tile_h,
                r = 0.05,
                colour = fill,
                emboss = 0.02,
            }, nodes = { tile_content } },
        }}
    }}
end

function LetterTile.word_row(card_snapshots, width, max_scale)
    local nodes = {}
    local count = math.max(1, #card_snapshots)
    local scale = width / (count * 0.70)
    local cap = max_scale or 0.58
    if scale > cap then scale = cap end

    for _, snap in ipairs(card_snapshots) do
        nodes[#nodes + 1] = LetterTile.ui_node(snap, scale)
    end

	return { n = G.UI.COLUMN, config = { align = "cl", maxw = width }, nodes = nodes }
end

return LetterTile
