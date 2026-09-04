--[[ app/callbacks/overlays/ ]]


local Scheduler = require "app.effects.timeline_scheduler"
G.FUNCS.switch_tab = function(e)
  if not e then return end
  clear_overlay_infotip()

  local tab_contents = e.LayoutView:find_node_by_id('tab_contents')
  tab_contents.config.object:remove()
  tab_contents.config.object = LayoutView{
      definition = e.config.ref_table.tab_definition_function(e.config.ref_table.tab_definition_function_args),
      config = {offset = {x=0,y=0}, parent = tab_contents, type = 'cm'}
    }
  tab_contents.LayoutView:recalculate()
end
G.FUNCS.show_overlay  = function(args)
  if not args then return end
  --Remove any existing overlays if there is one
  if G.OVERLAY_MENU then G.OVERLAY_MENU:remove() end
  G.INPUT.locks.frame_set = true
  G.INPUT.locks.frame = true
  G.INPUT.press_state.target = nil
  G.INPUT:shift_context_layer(G.NO_MOD_CURSOR_STACK and 0 or 1)

  args.config = args.config or {}
  local stable_overlay = args.config.no_jiggle == true
  args.config = {
    align = args.config.align or "cm",
    offset = args.config.offset or (stable_overlay and {x=0,y=0} or {x=0,y=10}),
    major = args.config.major or G.ROOM_ATTACH,
    bond = 'Weak',
    no_esc = args.config.no_esc,
    no_jiggle = args.config.no_jiggle,
  }
  G.OVERLAY_MENU = true
  --Generate the LayoutView
  G.OVERLAY_MENU = LayoutView{
    definition = args.definition,
    config = args.config
  }

  --Set the offset and align. The menu overlay can be initially offset in the y direction and this will ensure it slides to middle
  G.OVERLAY_MENU.alignment.offset.y = stable_overlay and (args.config.offset.y or 0) or 0
  if G.ROOM and not stable_overlay then G.ROOM.jiggle = (G.ROOM.jiggle or 0) + 1 end
  G.OVERLAY_MENU:align_to_major()
  if stable_overlay then
    G.OVERLAY_MENU.NEW_ALIGNMENT = false
    G.OVERLAY_MENU.VT.x = G.OVERLAY_MENU.T.x
    G.OVERLAY_MENU.VT.y = G.OVERLAY_MENU.T.y
    G.OVERLAY_MENU.VT.w = G.OVERLAY_MENU.T.w
    G.OVERLAY_MENU.VT.h = G.OVERLAY_MENU.T.h
  end
end

--Removes the overlay menu if one exists, unpauses the game, and saves the settings to file
G.FUNCS.close_overlay = function()
  if not G.OVERLAY_MENU then return end
  G.INPUT.locks.frame_set = true
  G.INPUT.locks.frame = true
  G.INPUT:shift_context_layer(-1000)
  G.OVERLAY_MENU:remove()
  G.OVERLAY_MENU = nil
  G.VIEWING_DECK = nil
  G.SETTINGS.paused = false

  --Save settings to file
  G:queue_settings_write()
end

