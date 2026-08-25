--[[
	word_game/ui/card_popups.lua - Card popups, tooltips, badges, and unlock overlays.

	These UI definitions remain global because existing card and event call sites
	use them directly.
]]

local Easing = require "app.effects.easing"

function build_notify_alert(_achievement, _type)
  local _c = G.P_CENTERS and G.P_CENTERS[_achievement]
  local _atlas = 
    _type == 'Companion' and (G.TEXTURE_ATLASES["Companion"] or G.TEXTURE_ATLASES["centers"] or G.TEXTURE_ATLASES["cards_1"]) or
    _type == 'Perk' and (G.TEXTURE_ATLASES["Perk"] or G.TEXTURE_ATLASES["centers"] or G.TEXTURE_ATLASES["cards_1"]) or
    _type == 'Back' and (G.TEXTURE_ATLASES["centers"] or G.TEXTURE_ATLASES["cards_1"]) or
    (G.TEXTURE_ATLASES["icons"] or G.TEXTURE_ATLASES["centers"] or G.TEXTURE_ATLASES["cards_1"])

  _atlas = _atlas or {px = 71, py = 95, name = "cards_1"}
  local px = _atlas.px or 71
  local py = _atlas.py or 95

  local t_s = Sprite(0,0,1.5*(px/py),1.5,_atlas, _c and _c.pos or {x=3, y=0})
  t_s.states.drag.can = false
  t_s.states.hover.can = false
  t_s.states.collide.can = false
 
  local subtext = _type == 'achievement' and localize(G.F_TROPHIES and 'term_trophy' or 'term_achievement') or
    _type == 'Companion' and localize('term_joker') or 
    _type == 'Perk' and localize('term_perk') or
    _type == 'Back' and localize('term_deck') or 'ERROR'

  if _achievement == 'ui_challenge' then subtext = localize('term_challenges') end
  local name = _type == 'achievement' and localize(_achievement, 'achievement_names') or 'ERROR'

    local t = {n=G.UI.ROOT, config = {align = 'cl', r = 0.1, padding = 0.06, colour = G.C.UI.TRANSPARENT_DARK}, nodes={
    {n=G.UI.ROW, config={align = "cl", padding = 0.2, minw = 20, r = 0.1, colour = G.C.BLACK, outline = 1.5, outline_colour = G.C.GREY}, nodes={
      {n=G.UI.ROW, config={align = "cm", r = 0.1}, nodes={
        {n=G.UI.ROW, config={align = "cm", r = 0.1}, nodes={
          {n=G.UI.OBJECT, config={object = t_s}},
        }},
        _type ~= 'achievement' and {n=G.UI.ROW, config={align = "cm", padding = 0.04}, nodes={
          {n=G.UI.ROW, config={align = "cm", maxw = 3.4}, nodes={
            {n=G.UI.TEXT, config={text = subtext, scale = 0.5, colour = G.C.FILTER, shadow = true}},
          }},
          {n=G.UI.ROW, config={align = "cm", maxw = 3.4}, nodes={
            {n=G.UI.TEXT, config={text = localize('term_unlocked_ex'), scale = 0.35, colour = G.C.FILTER, shadow = true}},
          }}
        }}
        or {n=G.UI.ROW, config={align = "cm", padding = 0.04}, nodes={
          {n=G.UI.ROW, config={align = "cm", maxw = 3.4, padding = 0.1}, nodes={
            {n=G.UI.TEXT, config={text = name, scale = 0.4, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
          }},
          {n=G.UI.ROW, config={align = "cm", maxw = 3.4}, nodes={
            {n=G.UI.TEXT, config={text = subtext, scale = 0.3, colour = G.C.FILTER, shadow = true}},
          }},
          {n=G.UI.ROW, config={align = "cm", maxw = 3.4}, nodes={
            {n=G.UI.TEXT, config={text = localize('term_unlocked_ex'), scale = 0.35, colour = G.C.FILTER, shadow = true}},
          }}
        }}
      }}
    }}
  }}
  return t
end


function G.DEFINITIONS.card_focus_ui(card)
  local card_width = card.T.w

  local playing_card_colour = deep_clone(G.C.WHITE)
  playing_card_colour[4] = 1.5
  if G.hand and card.area == G.hand then Easing.value{ref_table = playing_card_colour, ref_value = 4, mod = -1.5, timer = 'REAL', delay = 0.2, ease = 'quad'} end

  local t_card_norm = {x = card.T.x + card.T.w/2 - G.ROOM.T.w/2, y = card.T.y + card.T.h/2 - G.ROOM.T.h/2}

  local base_background = LayoutView{
    T = {card.VT.x,card.VT.y,0,0},
    definition = 
      (not G.hand or card.area ~= G.hand) and {n=G.UI.ROOT, config = {align = 'cm', minw = card_width + 0.3, minh = card.T.h + 0.3, r = 0.1, colour = with_alpha(G.C.BLACK, 0.7), outline_colour = tint(G.C.MUTED_GREY, 0.5), outline = 1.5, line_emboss = 0.8}, nodes={
        {n=G.UI.ROW, config={id = 'ATTACH_TO_ME'}, nodes={}}
      }} or 
      {n=G.UI.ROOT, config = {align = 'cm', minw = card_width, minh = card.T.h, r = 0.1, colour = playing_card_colour}, nodes={
        {n=G.UI.ROW, config={id = 'ATTACH_TO_ME'}, nodes={}}
      }},
    config = {
        align = 'cm',
        offset = {x= 0.007*t_card_norm.x*card.T.w, y = 0.007*t_card_norm.y*card.T.h}, 
        parent = card,
        r_bond = (not G.hand or card.area ~= G.hand) and 'Weak' or 'Strong'
      }
  }

  base_background.set_alignment = function()
    local card_norm = {x = card.T.x + card.T.w/2 - G.ROOM.T.w/2, y = card.T.y + card.T.h/2 - G.ROOM.T.h/2}
    EaseNode.set_alignment(card.children.focused_ui, {offset = {x= 0.007*card_norm.x*card.T.w, y = 0.007*card_norm.y*card.T.h}})
  end

  return base_background
end


function desc_from_rows(desc_nodes, empty, maxw)
  local t = {}
  for k, v in ipairs(desc_nodes) do
    t[#t+1] = {n=G.UI.ROW, config={align = "cm", maxw = maxw}, nodes=v}
  end
  return {n=G.UI.ROW, config={align = "cm", colour = empty and G.C.CLEAR or G.C.UI.BACKGROUND_WHITE, r = 0.1, padding = 0.04, minw = 2, minh = 0.8, emboss = not empty and 0.05 or nil, filler = true}, nodes={
    {n=G.UI.ROW, config={align = "cm", padding = 0.03}, nodes=t}
  }}
end


function transparent_multiline_text(desc_nodes)
  local t = {}
  for k, v in ipairs(desc_nodes) do
    t[#t+1] = {n=G.UI.ROW, config={align = "cm"}, nodes=v}
  end
  return {n=G.UI.ROW, config={align = "cm", padding = 0.03}, nodes=t}
end


function rows_to_infotip(desc_nodes, name)
  local t = {}
  for k, v in ipairs(desc_nodes) do
    t[#t+1] = {n=G.UI.ROW, config={align = "cm"}, nodes=v}
  end
  return {n=G.UI.ROW, config={align = "cm", colour = tint(G.C.GREY, 0.15), r = 0.1}, nodes={
    {n=G.UI.ROW, config={align = "tm", minh = 0.36, padding = 0.03}, nodes={{n=G.UI.TEXT, config={text = name, scale = 0.32, colour = G.C.UI.TEXT_LIGHT}}}},
    {n=G.UI.ROW, config={align = "cm", minw = 1.5, minh = 0.4, r = 0.1, padding = 0.05, colour = G.C.WHITE}, nodes={{n=G.UI.ROW, config={align = "cm", padding = 0.03}, nodes=t}}}
  }}
end


function overlay_infotip(text_rows)
  local t = {}
  if type(text_rows) ~= 'table' then text_rows = {"ERROR"} end
  for k, v in ipairs(text_rows) do
    t[#t+1] = {n=G.UI.ROW, config={align = "cm"}, nodes={
      {n=G.UI.TEXT, config={text = v,colour = G.C.UI.TEXT_LIGHT, scale = 0.45, bounce = true, shadow = true, lang = text_rows.lang}}
    }}
  end
  return {n=G.UI.ROOT, config={align = "cm", colour = G.C.CLEAR, padding = 0.1}, nodes=t}
end


function name_from_rows(name_nodes, background_colour)
  if not name_nodes or (type(name_nodes) ~= 'table') or not next(name_nodes) then return end
  return {n=G.UI.ROW, config={align = "cm", padding = 0.05, r = 0.1, colour = background_colour, emboss = background_colour and 0.05 or nil}, nodes=name_nodes}
end


function G.DEFINITIONS.card_h_popup(card)
  if card.tooltip_info then
    local tip = card.tooltip_info
    local debuffed = card.debuff
    local card_type_colour = get_type_colour(card.config.center or card.config, card)
    local card_type_background = 
        (tip.card_type == 'Locked' and G.C.BLACK) or 
        ((tip.card_type == 'Undiscovered') and shade(G.C.MUTED_GREY, 0.3)) or 
        (tip.card_type == 'Enhanced' or tip.card_type == 'Default') and shade(G.C.BLACK, 0.1) or
        (debuffed and shade(G.C.BLACK, 0.1)) or 
        (card_type_colour and shade(G.C.BLACK, 0.1)) or
        G.C.SET[tip.card_type] or
        {0, 1, 1, 1}

    local outer_padding = 0.05
    local card_type = localize('term_'..string.lower(tip.card_type))

    if tip.card_type == 'Companion' or (tip.badges and tip.badges.force_rarity) then card_type = ({localize('term_common'), localize('term_uncommon'), localize('term_rare'), localize('term_legendary')})[card.config.center.rarity] end
    if tip.card_type == 'Enhanced' then card_type = localize{type = 'name_text', key = card.config.center.key, set = 'Enhanced'} end
    card_type = (debuffed and tip.card_type ~= 'Enhanced') and localize('term_debuffed') or card_type

    local disp_type, is_playing_card = 
              (tip.card_type ~= 'Locked' and tip.card_type ~= 'Undiscovered' and tip.card_type ~= 'Default') or debuffed,
              tip.card_type == 'Enhanced' or tip.card_type == 'Default'

    local info_boxes = {}
    local badges = {}

    if tip.badges.card_type or tip.badges.force_rarity then
      badges[#badges + 1] = make_badge(card_type, card_type_colour, nil, 1.2)
    end
    if tip.badges then
      for k, v in ipairs(tip.badges) do
        if v == 'negative_consumable' then v = 'negative' end
        badges[#badges + 1] = make_badge(localize(v, "labels"), get_badge_colour(v))
      end
    end

    if tip.info then
      for k, v in ipairs(tip.info) do
        info_boxes[#info_boxes+1] =
        {n=G.UI.ROW, config={align = "cm"}, nodes={
        {n=G.UI.ROW, config={align = "cm", colour = tint(G.C.MUTED_GREY, 0.5), r = 0.1, padding = 0.05, emboss = 0.05}, nodes={
          rows_to_infotip(v, v.name),
        }}
      }}
      end
    end

    return {n=G.UI.ROOT, config = {align = 'cm', colour = G.C.CLEAR}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", func = 'show_infotip',object = EaseNode(),ref_table = next(info_boxes) and info_boxes or nil}, nodes={
        {n=G.UI.ROW, config={padding = outer_padding, r = 0.12, colour = tint(G.C.MUTED_GREY, 0.5), emboss = 0.07}, nodes={
          {n=G.UI.ROW, config={align = "cm", padding = 0.07, r = 0.1, colour = with_alpha(card_type_background, 0.8)}, nodes={
            name_from_rows(tip.name, is_playing_card and G.C.WHITE or nil),
            desc_from_rows(tip.main),
            badges[1] and {n=G.UI.ROW, config={align = "cm", padding = 0.03}, nodes=badges} or nil,
          }}
        }}
      }},
    }}
  end
end


function get_badge_colour(key)
  G.BADGE_COL = G.BADGE_COL or {

    foil = G.C.DARK_FINISH,
    holographic = G.C.DARK_FINISH,
    polychrome = G.C.DARK_FINISH,
    negative = G.C.DARK_FINISH,
    gold_seal = G.C.GOLD,
    red_seal = G.C.RED,
    blue_seal = G.C.BLUE,
    purple_seal = G.C.PURPLE,
    pinned_left = G.C.ORANGE,
  }
  return G.BADGE_COL[key] or {1, 0, 0, 1}
end


function make_badge(_string, _badge_col, _text_col, scaling)
  scaling = scaling or 1
  return {n=G.UI.ROW, config={align = "cm"}, nodes={
    {n=G.UI.ROW, config={align = "cm", colour = _badge_col or G.C.GREEN, r = 0.1, minw = 2, minh = 0.4*scaling, emboss = 0.05, padding = 0.03*scaling}, nodes={
      {n=G.UI.BOX, config={h=0.1,w=0.03}},
      {n=G.UI.OBJECT, config={object = FlowText({string = _string or 'ERROR', colours = {_text_col or G.C.WHITE},float = true, shadow = true, offset_y = -0.05, silent = true, spacing = 1, scale = 0.33*scaling})}},
      {n=G.UI.BOX, config={h=0.1,w=0.03}},
    }}
  }}
end


function build_detailed_tooltip(_center)
  local full_UI_table = {
      main = {},
      info = {},
      type = {},
      name = 'done',
      badges = {}
  }
  local desc = generate_card_ui(_center, full_UI_table, nil, _center.set, nil)
  return {n=G.UI.ROOT, config={align = "cm", colour = G.C.CLEAR}, nodes={
    {n=G.UI.ROW, config={align = "cm", colour = tint(G.C.MUTED_GREY, 0.5), r = 0.1, padding = 0.05, emboss = 0.05}, nodes={
      rows_to_infotip(desc.info[1], desc.info[1].name),
    }}
  }}
end


function make_tooltip(tooltip)
  local title = tooltip.title or nil
  local text = tooltip.text or {}
  local rows = {}
  if title then
      local r = {n=G.UI.ROW, config={align = "cm"}, nodes={
          {n=G.UI.COLUMN, config={align = "cm"}, nodes={
              {n=G.UI.TEXT, config={text = title,colour = G.C.UI.TEXT_DARK, scale = 0.4}}}}}}
      table.insert(rows, r)
  end
  for i = 1, #text do
    if type(text[i]) == 'table' then
      local r = {n=G.UI.ROW, config={align = "cm", padding = 0.03}, nodes={
        {n=G.UI.TEXT, config={ref_table = text[i].ref_table, ref_value = text[i].ref_value,colour = G.C.UI.TEXT_DARK, scale = 0.4}}}}
      table.insert(rows, r)
    else
      local r = {n=G.UI.ROW, config={align = "cm", padding = 0.03}, nodes={
              {n=G.UI.TEXT, config={text = text[i],colour = G.C.UI.TEXT_DARK, scale = 0.4}}}}
      table.insert(rows, r)
    end
  end
  if tooltip.filler then 
    table.insert(rows, tooltip.filler.func(tooltip.filler.args))
  end
  local t = {
      n=G.UI.ROOT, config = {align = "cm", padding = 0.05, r=0.1, colour = G.C.RED, emboss = 0.05}, nodes=
      {{n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, colour = G.C.WHITE, emboss = 0.05}, nodes=rows}}}
  return t
end


return true
