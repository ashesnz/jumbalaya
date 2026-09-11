--[[
	Analyzer-only Love2D stubs for IntelliJ EmmyLua.
	Love never requires this file. Cursor LuaLS already uses ${3rd}/love2d/library.
	Callbacks and subsystems are optional (`|nil`) so `if love.timer then` is not
	always-true / always-false.
]]

---@meta

---@class love.Image
local Image = {}
function Image:getDimensions() end
function Image:getWidth() end
function Image:getHeight() end
function Image:setFilter(min, mag) end

---@class love.Canvas
local Canvas = {}
function Canvas:setFilter(min, mag) end

---@class love.Quad

---@class love.Video
local Video = {}
function Video:getWidth() end
function Video:getHeight() end
function Video:release() end

---@class love.Shader
local Shader = {}
function Shader:send(name, ...) end

---@class love.Source
local Source = {}
function Source:isPlaying() end
function Source:stop() end
function Source:play() end

---@class love.Font
local Font = {}
function Font:hasGlyphs(...) end

---@class love.Thread
local Thread = {}
function Thread:start(...) end

---@class love.Channel
local Channel = {}
function Channel:pop() end
function Channel:push(...) end
function Channel:demand() end

---@class love.Joystick
local Joystick = {}
function Joystick:isGamepad() end
function Joystick:setVibration(...) end

---@class love.GraphicsLib
local GraphicsLib = {}
function GraphicsLib.push() end
function GraphicsLib.pop() end
function GraphicsLib.scale(sx, sy) end
function GraphicsLib.translate(x, y) end
function GraphicsLib.rotate(r) end
function GraphicsLib.setColor(...) end
function GraphicsLib.setShader(...) end
function GraphicsLib.draw(...) end
function GraphicsLib.newQuad(x, y, w, h, sw, sh) end
function GraphicsLib.newText(...) end
---@return love.Font
function GraphicsLib.newFont(...) end
function GraphicsLib.setNewFont(...) end
function GraphicsLib.setLineWidth(width) end
function GraphicsLib.setLineStyle(style) end
function GraphicsLib.setDefaultFilter(...) end
function GraphicsLib.rectangle(...) end
function GraphicsLib.print(...) end
function GraphicsLib.printf(...) end
function GraphicsLib.setCanvas(...) end
function GraphicsLib.clear(...) end
function GraphicsLib.present() end
function GraphicsLib.origin() end
function GraphicsLib.reset() end
---@return boolean
function GraphicsLib.isActive() end
---@return boolean
function GraphicsLib.isCreated() end
---@return love.Shader
function GraphicsLib.newShader(path) end
---@return love.Image
function GraphicsLib.newImage(path, settings) end
---@return love.Canvas
function GraphicsLib.newCanvas(...) end
function GraphicsLib.setBackgroundColor(...) end
function GraphicsLib.getBackgroundColor() end
function GraphicsLib.getWidth() end
function GraphicsLib.getHeight() end

---@class love.TimerLib
local TimerLib = {}
---@return number
function TimerLib.getTime() end
function TimerLib.sleep(s) end
---@return number
function TimerLib.step() end

---@class love.WindowLib
local WindowLib = {}
function WindowLib.getDisplayCount() end
function WindowLib.getMode() end
function WindowLib.getDesktopDimensions(display) end
function WindowLib.getFullscreenModes(display) end
function WindowLib.setTitle(title) end
function WindowLib.setMode(...) end
---@return boolean
function WindowLib.isOpen() end
function WindowLib.toPixels(value) end
function WindowLib.getTitle() end
function WindowLib.showMessageBox(...) end

---@class love.MouseLib
local MouseLib = {}
function MouseLib.getPosition() end
function MouseLib.setVisible(visible) end
function MouseLib.setGrabbed(grabbed) end
function MouseLib.setRelativeMode(enable) end

---@class love.FilesystemLib
local FilesystemLib = {}
function FilesystemLib.remove(name) end
---@return string|nil
function FilesystemLib.read(...) end
function FilesystemLib.write(...) end
---@return table|nil
function FilesystemLib.getInfo(...) end
---@return string[]
function FilesystemLib.getDirectoryItems(dir) end
function FilesystemLib.createDirectory(...) end
function FilesystemLib.append(...) end
---@return string|nil
function FilesystemLib.getSaveDirectory() end
function FilesystemLib.getSourceBaseDirectory() end

---@class love.AudioLib
local AudioLib = {}
function AudioLib.newSource(...) end
function AudioLib.play(...) end
function AudioLib.setVolume(...) end
function AudioLib.stop() end

---@class love.SystemLib
local SystemLib = {}
---@return string
function SystemLib.getOS() end

---@class love.ThreadLib
local ThreadLib = {}
---@return love.Thread
function ThreadLib.newThread(name) end
---@return love.Channel
function ThreadLib.getChannel(name) end

---@class love.JoystickLib
local JoystickLib = {}
function JoystickLib.loadGamepadMappings(file) end
---@return love.Joystick[]
function JoystickLib.getJoysticks() end

---@class love.EventLib
local EventLib = {}
function EventLib.pump() end
---@return fun(): string?, any, any, any, any, any, any
function EventLib.poll() end

---@class love.TouchLib
local TouchLib = {}
---@return table
function TouchLib.getTouches() end

---@class love.ArgLib
local ArgLib = {}
---@param a string[]
---@return table
function ArgLib.parseGameArguments(a) end

---@class (partial) love
---@field graphics love.GraphicsLib
---@field timer love.TimerLib
---@field window love.WindowLib
---@field mouse love.MouseLib
---@field filesystem love.FilesystemLib
---@field audio love.AudioLib
---@field system love.SystemLib
---@field thread love.ThreadLib
---@field joystick love.JoystickLib
---@field event love.EventLib
---@field touch love.TouchLib
---@field arg love.ArgLib
---@field handlers table<string, fun(...)>
---@field load fun(args: table, unfilteredArg: string[])|nil
---@field update fun(dt: number)|nil
---@field draw fun()|nil
---@field quit fun(): boolean|nil
love = {}

---@type string[]
arg = {}

---@class jit
---@field arch string
---@field off fun()
jit = {}

---@param x number
function math.randomseed(x) end

---@param chunk string
---@return function|nil
function loadstring(chunk) end
