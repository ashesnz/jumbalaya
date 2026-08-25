--[[
	word_game/ui/stats.lua - Profile stats, usage, and high-score rows.

	These stay globals (`build_*`, `G.DEFINITIONS.*`) so existing call sites
	do not change. Loaded from main.lua.
]]

local Components = require "word_game.ui.widgets.components"

function build_high_scores_filling(_resp)
  local scores = {}
  local loader = loadstring(_resp)
  if type(loader) ~= 'function' then
    return {n=G.UI.ROOT, config = {align = 'cm', r = 0.1, colour = G.C.L_BLACK, padding = 0.05}, nodes={
      {n=G.UI.ROW, config={align = "cm", padding = 0.1, minh = 1.3}, nodes={
        {n=G.UI.TEXT, config={text = 'ERROR', scale = 0.9, colour = G.C.RED, shadow = true}},
      }}
    }}
  end
  _resp = loader()
  if not _resp then 
    return {n=G.UI.ROOT, config = {align = 'cm', r = 0.1, colour = G.C.L_BLACK, padding = 0.05}, nodes={
      {n=G.UI.ROW, config={align = "cm", padding = 0.1, minh = 1.3}, nodes={
        {n=G.UI.TEXT, config={text = 'ERROR', scale = 0.9, colour = G.C.RED, shadow = true}},
      }}
    }}
  end
  for i = 1, 6 do
    local v = _resp[i] or {username = '-'}
    v.score = v.score and math.floor(v.score) or nil
    local name_col = v.username == (G.SETTINGS.COMP and G.SETTINGS.COMP.name or nil) and G.C.FILTER or G.C.WHITE
    scores[#scores+1] = {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes={
      {n=G.UI.COLUMN, config={align = "cl", padding = 0, minw = 0.3}, nodes={
        {n=G.UI.TEXT, config={text = i..'.', scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
      }},
      {n=G.UI.COLUMN, config={align = "cl", padding = 0, minw = 1.7, maxw = 1.6}, nodes={
        {n=G.UI.TEXT, config={text = (v.username), scale = math.min(0.6, 8*0.56/v.username:len()), colour = v.score and name_col or G.C.UI.TRANSPARENT_LIGHT, shadow = true}}
      }},
      {n=G.UI.COLUMN, config={align = "cl", minh = 0.8, r = 0.1, minw = 2.5, colour = G.C.BLACK, emboss = 0.05}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minw = 2.6}, nodes={
          {n=G.UI.COLUMN, config={align = "cm"}, nodes={
            {n=G.UI.OBJECT, config={object = FlowText({string = {type(v.score) == 'number' and number_format(v.score) or ''}, colours = {G.C.RED},shadow = true, float = true,maxw = 2.5, scale = math.min(0.75, score_number_scale(1.5, v.score))})}},
          }},
        }},
      }},
    }}
  end
  return {n=G.UI.ROOT, config = {align = 'cm', r = 0.1, colour = G.C.L_BLACK, padding = 0.05}, nodes=scores}
end


function G.DEFINITIONS.usage_tabs()
  return build_generic_options({back_func = 'show_high_scores', contents ={make_tab_strip(
    {tabs = {
        {
          label = localize('ui_stat_jokers'),
          chosen = true,
          tab_definition_function = build_usage,
          tab_definition_function_args = {'tile_usage'},
        },
        {
          label = localize('ui_stat_consumables'),
          tab_definition_function = build_usage,
          tab_definition_function_args = {'usable_usage'},
        },
        {
          label = localize('ui_stat_perks'),
          tab_definition_function = build_usage,
          tab_definition_function_args = {'bonus_usage', 'Perk'},
        },
    },
    tab_h = 8,
    snap_to_nav = true})}})
end


function build_usage(args)
  args = args or {}
  local _type, _set = args[1], args[2]
  ---@type {count: number, key: string}[]
  local used_cards = {}
  local max_amt = 0
  for k, v in pairs(G.PROFILES[G.SETTINGS.profile][_type]) do
    if G.P_CENTERS[k] and (not _set or G.P_CENTERS[k].set == _set) and G.P_CENTERS[k].discovered then
      used_cards[#used_cards + 1] = {count = v.count, key = k}
      if v.count > max_amt then max_amt = v.count end
    end
  end

  local _col = G.C.SECONDARY_SET[_set] or G.C.RED

  table.sort(used_cards, function (a, b) return a.count > b.count end )

  local histograms = {}

  for i = 1, 10 do
    local v = used_cards[i]
    if v then 
      local card = Card(0,0, 0.7*G.CARD_W, 0.7*G.CARD_H, nil, G.P_CENTERS[v.key])
      card.ambient_tilt = 0.8
      local cardarea = CardArea(
        G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
        G.CARD_W*0.7,
        G.CARD_H*0.7, 
        {card_limit = 2, type = 'title', selection_limit = 0})
      cardarea:emplace(card)

      histograms[#histograms +1] = 
      {n=G.UI.COLUMN, config={align = "bm",minh = 6.2,  colour = G.C.UI.TRANSPARENT_DARK, r = 0.1}, nodes={
        
        {n=G.UI.ROW, config={align = "bm"}, nodes={
          {n=G.UI.ROW, config={align = "cm", minh = 0.7*G.CARD_H+0.1} , nodes={
            {n=G.UI.OBJECT, config={object = cardarea}}
          }},
          {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UI.TEXT, config={text = v.count, scale = 0.35, colour = blend_colours(G.C.FILTER, G.C.WHITE, 0.8), shadow = true}}
          }},
          {n=G.UI.ROW, config={align = "cm"}, nodes={
            {n=G.UI.ROW, config={align = "cm", minh = v.count/max_amt*3.6, minw = 0.8, colour = G.C.SECONDARY_SET[G.P_CENTERS[v.key].set] or G.C.RED, res = 0.15, r = 0.001}, nodes={}},
          }},
        }},
      }}
    else
      histograms[#histograms +1] = 
      {n=G.UI.COLUMN, config={align = "bm",minh = 6.2,  colour = G.C.UI.TRANSPARENT_DARK, r = 0.1}, nodes={
        {n=G.UI.ROW, config={align = "bm"}, nodes={
          {n=G.UI.ROW, config={align = "cm", minh = 0.7*G.CARD_H+0.1, minw = 0.7*G.CARD_W} , nodes={
          }},
          {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
            {n=G.UI.TEXT, config={text = '-', scale = 0.35, colour = blend_colours(G.C.FILTER, G.C.WHITE, 0.8), shadow = true}}
          }},
          {n=G.UI.ROW, config={align = "cm"}, nodes={
            {n=G.UI.ROW, config={align = "cm", minh = 0.2, minw = 0.8, colour = G.C.UI.TRANSPARENT_LIGHT, res = 0.15, r = 0.001}, nodes={}},
          }},
        }},
      }}
    end
  end

  local t = {n=G.UI.ROOT, config={align = "cm", minw = 3, padding = 0.1, r = 0.1, colour = G.C.UI.TRANSPARENT_DARK}, nodes={
    {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes={
      {n=G.UI.BOX, config={w=0.2,h=0.2,r =0.1,colour = G.C.FILTER}},
      {n=G.UI.TEXT, config={text = 
        _type == 'tile_usage' and localize('hdr_stat_joker') or
        _type == 'usable_usage' and localize('hdr_stat_consumable') or
        _type == 'bonus_usage' and localize('hdr_stat_perk'),
       scale = 0.35, colour = G.C.WHITE}}
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes=histograms},
  }}

  return t
end


function build_high_scores()
  fetch_achievements()
  set_profile_progress()
  sync_discover_counts()

  local scores = {
    build_high_scores_row("hand"),
    build_high_scores_row("furthest_round"),
    build_high_scores_row("furthest_set"),
    build_high_scores_row("most_points"),
    build_high_scores_row("win_streak"),
  }
  G.focused_profile = G.SETTINGS.profile
  local cheevs = {}
  
  local t = build_generic_options({ back_func = 'open_options', snap_back = true, contents = {
    {n=G.UI.COLUMN, config={align = "cm", minw = 3, padding = 0.2, r = 0.1, colour = G.C.CLEAR}, nodes={
      {n=G.UI.ROW, config={align = "cm", padding = 0.1}, nodes=
        scores
      },
    }},
    {n=G.UI.COLUMN, config={align = "cm", padding = 0.1, r = 0.1, colour = G.C.CLEAR}, nodes={
      make_progress_box(),
      Components.button({onClick = 'usage', label = {localize('term_card_stats')}, width = 7.5, height = 1, focus_args = {nav = 'wide'}}),
    }},
    not G.F_NO_ACHIEVEMENTS and {n=G.UI.COLUMN, config={align = "cm", r = 0.1, colour = G.C.CLEAR}, nodes=cheevs} or nil
  }})

  return t
end


function make_progress_box(_profile_progress, smaller)
  ---@type string[]
  local protos = {'collection', 'challenges', 'joker_stickers', 'deck_stake_wins'}
  local rows = {}
  _profile_progress = _profile_progress or G.PROFILES[G.SETTINGS.profile].progress

  
  _profile_progress.overall_tally, _profile_progress.overall_of = 
  _profile_progress.discovered.tally/_profile_progress.discovered.of +
  _profile_progress.deck_stakes.tally/_profile_progress.deck_stakes.of +
  _profile_progress.joker_stickers.tally/_profile_progress.joker_stickers.of +
  _profile_progress.challenges.tally/_profile_progress.challenges.of,
  4

  local text_scale = smaller and 0.7 or 1
  local bar_colour = G.PROFILES[G.focused_profile].all_unlocked and G.C.RED or G.C.BLUE

  for _, v in ipairs(protos) do
    local tab, val, max = nil,nil,nil
    if v == 'collection' then
      tab, val, max = _profile_progress.discovered, 'tally', _profile_progress.discovered.of
    elseif v == 'deck_stake_wins' then
      tab, val, max = _profile_progress.deck_stakes, 'tally', _profile_progress.deck_stakes.of
    elseif v == 'joker_stickers' then
      tab, val, max = _profile_progress.joker_stickers, 'tally', _profile_progress.joker_stickers.of
    elseif v == 'challenges' then
      tab, val, max = _profile_progress.challenges, 'tally', _profile_progress.challenges.of
    end
    local filling = v == 'collection' and {
      {n=G.UI.OBJECT, config={object = FlowText({string = {math.floor(0.01+100*_profile_progress.discovered.tally/_profile_progress.discovered.of)..'%'}, colours = {G.C.WHITE},shadow = true, float = true, scale = 0.55*text_scale})}},
      {n=G.UI.TEXT, config={text = " (".._profile_progress.discovered.tally..'/'.._profile_progress.discovered.of..")", scale = 0.35, colour = G.C.MUTED_GREY}}
    } or v == 'deck_stake_wins' and {
      {n=G.UI.OBJECT, config={object = FlowText({string = {math.floor(0.01+100*_profile_progress.deck_stakes.tally/_profile_progress.deck_stakes.of)..'%'}, colours = {G.C.WHITE},shadow = true, float = true, scale = 0.55*text_scale})}},
      {n=G.UI.TEXT, config={text = " (".._profile_progress.deck_stakes.tally..'/'.._profile_progress.deck_stakes.of..")", scale = 0.35, colour = G.C.MUTED_GREY}}
    } or v == 'joker_stickers' and {
      {n=G.UI.OBJECT, config={object = FlowText({string = {math.floor(0.01+100*_profile_progress.joker_stickers.tally/_profile_progress.joker_stickers.of)..'%'}, colours = {G.C.WHITE},shadow = true, float = true, scale = 0.55*text_scale})}},
      {n=G.UI.TEXT, config={text = " (".._profile_progress.joker_stickers.tally..'/'.._profile_progress.joker_stickers.of..")", scale = 0.35, colour = G.C.MUTED_GREY}}
    } or v == 'challenges' and {
      {n=G.UI.OBJECT, config={object = FlowText({string = {math.floor(0.01+100*_profile_progress.challenges.tally/_profile_progress.challenges.of)..'%'}, colours = {G.C.WHITE},shadow = true, float = true, scale = 0.55*text_scale})}},
      {n=G.UI.TEXT, config={text = " (".._profile_progress.challenges.tally..'/'.._profile_progress.challenges.of..")", scale = 0.35, colour = G.C.MUTED_GREY}}
    }

    rows[#rows+1] = {n=G.UI.ROW, config={align = "cm", padding = 0.05, r = 0.1, colour = shade(G.C.MUTED_GREY, 0.1), emboss = 0.05}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, minw = 3.5*text_scale, maxw = 3.5*text_scale}, nodes={
          {n=G.UI.TEXT, config={text = localize('term_'..v), scale = 0.5*text_scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
      }},
      {n=G.UI.COLUMN, config={align = "cl", minh =smaller and 0.5 or 0.8, r = 0.1, minw = 3.5*text_scale, colour = G.C.BLACK, emboss = 0.05,
      progress_bar = {
        max = max, ref_table = tab, ref_value = val, empty_col = G.C.BLACK, filled_col = with_alpha(bar_colour, 0.5)
      }}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minw = 3.5*text_scale}, nodes=filling},
      }},
    }}
  end

  return {n=G.UI.ROW, config={align = "cm", padding = 0.05, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes={
    {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, minw = 3.5*text_scale, maxw = 3.5*text_scale}, nodes={
        {n=G.UI.TEXT, config={text = localize('term_progress'), scale = 0.5, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
      }},
      {n=G.UI.COLUMN, config={align = "cl", minh = 0.6, r = 0.1, minw = 3.5*text_scale, colour = G.C.BLACK, emboss = 0.05,
      progress_bar = {
        max = _profile_progress.overall_of, ref_table = _profile_progress, ref_value = 'overall_tally', empty_col = G.C.BLACK, filled_col = with_alpha(bar_colour, 0.5)
      }}, nodes={
        {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minw = 3.5*text_scale}, nodes={
          {n=G.UI.OBJECT, config={object = FlowText({string = {math.floor(0.01+100*_profile_progress.overall_tally/_profile_progress.overall_of)..'%'}, colours = {G.C.WHITE},shadow = true, float = true, scale = 0.55})}},
        }},
      }}
    }},
    {n=G.UI.ROW, config={align = "cm", padding = 0.05}, nodes=rows},
    }}
end


function build_high_scores_row(score)
  if not G.PROFILES[G.SETTINGS.profile].high_scores[score] then return nil end
  local label_scale = 0.65 - 0.025*math.max(string.len(G.PROFILES[G.SETTINGS.profile].high_scores[score].label)-8, 0)
  local label_w, score_w, h = 3.5, 4, 0.8
  local score_tab = {}
 
  if score == 'most_points' then 
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {localize('$')..number_format(G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)}, colours = {G.C.MONEY},shadow = true, float = true, scale = score_number_scale(0.85, G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)})}},
    }
  elseif score == 'win_streak' then 
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)}, colours = {G.C.WHITE},shadow = true, float = true, scale = score_number_scale(0.85, G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)})}},
      {n=G.UI.TEXT, config={text = " ("..G.PROFILES[G.SETTINGS.profile].high_scores["current_streak"].amt..")", scale = 0.45, colour = G.C.MUTED_GREY}}
    }
  elseif score == 'hand' then 
    local chip_sprite = Sprite(0,0,0.4,0.4,G.TEXTURE_ATLASES["ui_"..(G.SETTINGS.colourblind_option and 2 or 1)], {x=0, y=0})
    chip_sprite.states.drag.can = false
    score_tab = {
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
        {n=G.UI.OBJECT, config={w=0.4,h=0.4 , object = chip_sprite}}
      }},
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
        {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)}, colours = {G.C.RED},shadow = true, float = true, scale = math.min(0.75, score_number_scale(1.5, G.PROFILES[G.SETTINGS.profile].high_scores[score].amt))})}},
      }},
    }
  elseif score == 'collection' then 
    score_tab = {
      {n=G.UI.COLUMN, config={align = "cm"}, nodes={
        {n=G.UI.OBJECT, config={object = FlowText({string = {'%'..math.floor(0.01+100*G.PROFILES[G.SETTINGS.profile].high_scores[score].amt/G.PROFILES[G.SETTINGS.profile].high_scores[score].tot)}, colours = {G.C.WHITE},shadow = true, float = true, scale = math.min(0.75, score_number_scale(1.5, G.PROFILES[G.SETTINGS.profile].high_scores[score].amt))})}},
        {n=G.UI.TEXT, config={text = " ("..G.PROFILES[G.SETTINGS.profile].high_scores[score].amt..'/'..G.PROFILES[G.SETTINGS.profile].high_scores[score].tot..")", scale = 0.45, colour = G.C.MUTED_GREY}}
      }},
    }
  else
    score_tab = {
      {n=G.UI.OBJECT, config={object = FlowText({string = {number_format(G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)}, colours = {G.C.FILTER},shadow = true, float = true, scale = score_number_scale(0.85, G.PROFILES[G.SETTINGS.profile].high_scores[score].amt)})}},
    }
  end
  return {n=G.UI.ROW, config={align = "cm", padding = 0.05, r = 0.1, colour = shade(G.C.MUTED_GREY, 0.1), emboss = 0.05}, nodes={
    {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, minw = label_w, maxw = label_w}, nodes={
        {n=G.UI.TEXT, config={text = localize(score, 'show_high_scores'), scale = label_scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
    }},
    {n=G.UI.COLUMN, config={align = "cl", minh = h, r = 0.1, minw = score_w, colour = G.C.BLACK, emboss = 0.05}, nodes={
      {n=G.UI.COLUMN, config={align = "cm", padding = 0.05, r = 0.1, minw = score_w, maxw = score_w}, nodes=score_tab},
    }},
  }}
end


