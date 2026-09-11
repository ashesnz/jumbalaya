---@class Renderer
---@field draw_card fun(self: Renderer, view: table, rect: table)
---@field draw_text fun(self: Renderer, text: string, rect: table, style: table|nil)
---@field draw_sprite fun(self: Renderer, atlas: any, quad: any, rect: table, color: table|nil)

---@class InputService
---@field on_pointer_down fun(self: InputService, x: number, y: number): table
---@field on_action fun(self: InputService, action: table)
---@field action_for_func fun(self: InputService, name: string): table|nil
---@field dispatch_func fun(self: InputService, name: string, extra: table|nil): boolean

---@class AudioService
---@field play fun(self: AudioService, id: string, opts: table|nil)
---@field on_action fun(self: AudioService, action: table)
---@field bind_store fun(self: AudioService, store: table)

---@class Clock
---@field get_time fun(self: Clock): number
---@field advance fun(self: Clock, dt: number): number

---@class EngineContext
---@field store table
---@field renderer Renderer
---@field input InputService
---@field audio AudioService
---@field clock Clock
