--[[ app/core/input/router.lua - routes pointer, keyboard, and gamepad input ]]

local Kind = require("jumbalaya-engine.object")
local Scheduler = require("word_game.ui.effects.timeline_scheduler")

---@class InputRouter : Kind
InputRouter = Kind:derive("InputRouter")
InputController = InputRouter

InputRouter._input_actions = nil

function InputRouter:construct()
	-- Per-frame interaction records. `handled` false arms dispatch this frame.
	self.clicked    = {target = nil, handled = true, prev_target = nil}
	self.focused    = {target = nil, handled = true, prev_target = nil} -- gamepad only
	self.dragging   = {target = nil, handled = true, prev_target = nil}
	self.hovering   = {target = nil, handled = true, prev_target = nil}
	self.released_on = {target = nil, handled = true, prev_target = nil}

	-- Rebuilt every frame from the draw hash (topmost first).
	self.collision_list = {}
	self.nodes_at_cursor = {}

	self.press_state  = {T = {x = 0, y = 0}, target = nil, time = 0,   handled = true}
	self.release_state    = {T = {x = 0, y = 0}, target = nil, time = 0.1, handled = true}
	self.hover_state = {T = {x = 0, y = 0}, target = nil, time = 0,   handled = true}
	self.cursor_position = {x = 0, y = 0} -- screen pixels, not game units

	self.pressed_keys, self.held_keys = {}, {}
	self.held_key_times, self.released_keys = {}, {}

	self.pressed_buttons, self.held_buttons = {}, {}
	self.held_button_times, self.released_buttons = {}, {}

	self.interrupt = {focus = false}

	self.locks = {} -- arbitrary named locks set by game code
	self.locked = false

	self.axis_buttons = {
		l_stick = {current = '', previous = ''},
		r_stick = {current = '', previous = ''},
		l_trig  = {current = '', previous = ''},
		r_trig  = {current = '', previous = ''},
	}

	self.axis_cursor_speed = 20 -- game units per second of stick deflection

	self.button_registry = {} -- button name -> [{node, menu, click?}, ...]

	self.snap_cursor_to = nil

	-- Menu-depth memory so closing a menu restores prior cursor/focus.
	self.cursor_context = {layer = 1, stack = {}}

	self.cardarea_context = {}

	self.HID = {
		last_type = '',
		dpad = false,
		pointer = true,
		touch = false,
		controller = false,
		mouse = true,
		axis_cursor = false,
	}

	self.GAMEPAD = {object = nil, mapping = nil, name = nil}
	self.GAMEPAD_CONSOLE = ''

	-- Emulated gamepad used when keyboard keys are remapped to pad buttons.
	self.keyboard_controller = {
		getGamepadMappingString = function() return 'alpha_kbm' end,
		getGamepadAxis = function() return 0 end,
	}

	self.pointer_held = false
	self.frame_buttonpress = false -- one key/button action per frame latch
	self.deferred_press = nil      -- deferred left-press (resolved post-hover)
end

require("jumbalaya-engine.interaction.gamepad")(InputRouter)
require("jumbalaya-engine.interaction.hid")(InputRouter)
require("jumbalaya-engine.interaction.update_frame")(InputRouter)
require("jumbalaya-engine.interaction.update_interact")(InputRouter)
require("jumbalaya-engine.interaction.update_dispatch")(InputRouter)
require("jumbalaya-engine.interaction.registry")(InputRouter)
require("jumbalaya-engine.interaction.context")(InputRouter)
require("jumbalaya-engine.interaction.axis")(InputRouter)
require("jumbalaya-engine.interaction.bindings")(InputRouter)
require("jumbalaya-engine.interaction.queue")(InputRouter)
require("jumbalaya-engine.interaction.collision")(InputRouter)
require("jumbalaya-engine.interaction.pointer")(InputRouter)
require("jumbalaya-engine.interaction.focus_eligibility")(InputRouter)
require("jumbalaya-engine.interaction.focus_select")(InputRouter)
require("jumbalaya-engine.interaction.focus_capture")(InputRouter)
require("jumbalaya-engine.interaction.action_bridge").attach_router(InputRouter)

function InputRouter:update(dt)
    self:update_frame(dt)
    self:update_interact(dt)
    self:update_dispatch(dt)
end

return InputRouter
