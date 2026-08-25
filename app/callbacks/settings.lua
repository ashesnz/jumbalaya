-- Application settings, text input, overlay menus, and run lifecycle callbacks.

package.loaded["app.screen_wipe"] = nil
require "app.screen_wipe"

local modules = {
	"app.callbacks.ui_controls",
	"app.callbacks.window",
	"app.callbacks.overlays",
	"app.callbacks.run_lifecycle",
}

local function unload_callback_module(name)
	package.loaded[name] = nil
	local prefix = name .. "."
	for loaded_name in pairs(package.loaded) do
		if loaded_name:sub(1, #prefix) == prefix then
			package.loaded[loaded_name] = nil
		end
	end
end

for _, name in ipairs(modules) do
	unload_callback_module(name)
end
for _, name in ipairs(modules) do
	require(name)
end
