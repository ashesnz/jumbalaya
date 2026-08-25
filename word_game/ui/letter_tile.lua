--[[ word_game/ui/letter_tile.lua - Letter tile UI components for word history ]]

local LetterTile = {}

-- Simplified palette for the tiles
LetterTile.PALETTE = {
    red = {
        fill = { 0.8, 0.2, 0.2, 1 },
        text = { 1, 1, 1, 1 },
    },
    black = {
        fill = { 0.1, 0.1, 0.1, 1 },
        text = { 1, 1, 1, 1 },
    },
}

function LetterTile.snapshot_from_card(card)
    local letter = (card.ability and card.ability.letter)
        or (Dictionary and Dictionary.letter_from_card(card))
        or "?"
    local color = (card.ability and card.ability.letter_color)
        or (Dictionary and Dictionary.color_from_card(card))
        or "black"
    
    
    local atlas = nil
    local pos = nil
    if card.children and card.children.front then
        atlas = card.children.front.atlas
        pos = card.children.front.pos
    elseif card.config and card.config.card and card.config.card.pos then
        pos = card.config.card.pos
        atlas = G.TEXTURE_ATLASES[card.config.card.atlas] or G.TEXTURE_ATLASES["cards_"..(G.SETTINGS.colourblind_option and 2 or 1)]
    end

    return { 
        letter = letter, 
        letter_color = color,
        atlas = atlas,
        pos = pos
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
    local palette = LetterTile.PALETTE[snap.letter_color] or LetterTile.PALETTE.black
    local tile_w = 0.52 * scale
    local tile_h = 0.68 * scale

    local tile_content
    if snap.atlas and snap.pos then
        local sprite = Sprite(0, 0, tile_w, tile_h, snap.atlas, snap.pos)
        sprite.states.drag.can = false
        sprite.states.hover.can = false
        sprite.states.collide.can = false
        tile_content = { n = G.UI.OBJECT, config = { object = sprite } }
    else
        tile_content = { n = G.UI.TEXT, config = {
            text = snap.letter or "?",
            scale = 0.48 * scale,
            colour = palette.text,
            shadow = true,
        }}
    end

    return { n = G.UI.COLUMN, config = { align = "cm", padding = 0.008, maxw = tile_w + 0.02 }, nodes = {
        { n = G.UI.ROW, config = { align = "cm" }, nodes = {
            -- The Tile
            { n = G.UI.COLUMN, config = {
                align = "cm",
                minw = tile_w,
                maxw = tile_w,
                minh = tile_h,
                maxh = tile_h,
                r = 0.05,
                colour = palette.fill,
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
