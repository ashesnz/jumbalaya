-- Jumbalaya collection browser for deck backs and visual editions.
local Components = require "word_game.ui.widgets.components"

function build_card_gallery()
  sync_discover_counts()
  local t = build_generic_options({ back_func = G.STAGE == G.STAGES.RUN and 'open_options' or 'close_overlay', contents = {
    {n=G.UI.COLUMN, config={align = "cm", padding = 0.15}, nodes={
      Components.button({onClick = 'card_gallery_decks', label = {localize('ui_decks')}, count = G.DISCOVER_TALLIES.backs, width = 5}),
      Components.button({onClick = 'card_gallery_editions', label = {localize('ui_editions')}, count = G.DISCOVER_TALLIES.editions, width = 5, id = 'card_gallery_editions'}),
    }},
  }})
  return t
end

function build_card_gallery_editions()
  G.card_gallery = {}
  G.card_gallery[1] = CardArea(
    G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
    5.3*G.CARD_W,
    1.03*G.CARD_H,
    {card_limit = 5, type = 'title', selection_limit = 0, collection = true})
  local deck_tables =
  {n=G.UI.ROW, config={align = "cm", padding = 0, no_fill = true}, nodes={
    {n=G.UI.OBJECT, config={object = G.card_gallery[1]}}
  }}

  local editions = {'base', 'foil','holo','polychrome','negative'}

  for i = 1, 5 do
      local card = Card(G.card_gallery[1].T.x + G.card_gallery[1].T.w/2, G.card_gallery[1].T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS['e_'..editions[i]])
      card:begin_materialize()
      if G.P_CENTERS['e_'..editions[i]].discovered then card:set_edition({[editions[i]] = true}, true, true) end
      G.card_gallery[1]:emplace(card)
  end

  INIT_COLLECTION_CARD_ALERTS()

  local t = build_generic_options({ infotip = localize('opt_edition_seal_enhancement_explanation'), back_func = 'card_gallery', snap_back = true, contents = {
            {n=G.UI.ROW, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes={deck_tables}},
          }})
  return t
end

function build_card_gallery_decks()
  G.GAME.viewed_back = WORD_GAME.Back.new(G.P_CENTERS.deck_alpha)

  local area = CardArea(
    G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
    1.2*G.CARD_W,
    1.2*G.CARD_H,
    {card_limit = 52, type = 'deck', selection_limit = 0})

  for i = 1, 52 do
    local card = Card(G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h, G.CARD_W*1.2, G.CARD_H*1.2, pick_random(G.P_CARDS), G.P_CENTERS.letter_base, {playing_card = i, viewed_back = true})
    card.sprite_facing = 'back'
    card.facing = 'back'
    area:emplace(card)
  end

  local ordered_names = {}
  for _, v in ipairs(G.P_CENTER_POOLS.Back) do
    ordered_names[#ordered_names+1] = v.name
  end

  local t = build_generic_options({ back_func = 'card_gallery', contents = {
    Components.cycler({options = ordered_names, onChange = 'change_viewed_back', current_option = 1, colour = G.C.RED, width = 4.5, focus_args = {snap_to = true}, mid =
            {n=G.UI.ROW, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes={
              {n=G.UI.ROW, config={align = "cm", padding = 0.2, colour = G.C.BLACK, r = 0.2}, nodes={
                {n=G.UI.COLUMN, config={align = "cm", padding = 0}, nodes={
                  {n=G.UI.OBJECT, config={object = area}}
                }},
                {n=G.UI.COLUMN, config={align = "tm", minw = 3.7, minh = 2.1, r = 0.1, colour = G.C.L_BLACK, padding = 0.1}, nodes={
                  {n=G.UI.ROW, config={align = "cm", emboss = 0.1, r = 0.1, minw = 4, maxw = 4, minh = 0.6}, nodes={
                    {n=G.UI.OBJECT, config={object = FlowText({string = G.GAME.viewed_back:get_name(), maxw = 4, colours = {G.C.WHITE}, shadow = true, bump = true, scale = 0.5, pop_in = 0, silent = true})}},
                  }},
                  {n=G.UI.ROW, config={align = "cm", colour = G.C.WHITE, emboss = 0.1, minh = 2.2, r = 0.1}, nodes={
                    {n=G.UI.OBJECT, config={object = LayoutView{definition = G.GAME.viewed_back:generate_UI(), config = {offset = {x=0,y=0}}}}}
                  }}
                }},
              }},
            }}}),
          }})
  return t
end

return true
