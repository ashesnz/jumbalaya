---@class Renderer
---@field draw_card fun(self: Renderer, view: table, rect: table)
---@field draw_text fun(self: Renderer, text: string, rect: table, style: table)
---@field draw_sprite fun(self: Renderer, atlas: string, quad: any, rect: table, color: table)

---@class InputService
---@field on_pointer_down fun(self: InputService, x: number, y: number): table
---@field on_action fun(self: InputService, action: table)

---@class AudioService
---@field play fun(self: AudioService, id: string, opts: table|nil)

---@class Clock
---@field get_time fun(self: Clock): number
---@field advance fun(self: Clock, dt: number): number
