-- Two independent Lua functions: one plain checkbox, one with an editable bind.
-- F6 toggles the bound function by default. Change/clear it in the Lua menu.
local plain = ui.create("checkbox", "bind_demo_plain", "Plain Lua function", false)
local hotkey = ui.create("checkbox", "bind_demo_hotkey", "Bound Lua function", false,
    {key = 117, mode = 0}) -- VK_F6, toggle

events.on("paint", function()
    if ui.get(plain) then
        render.text(40, 180, "Plain Lua function: ON", {120, 220, 150, 255})
    end
    if ui.get(hotkey) then
        render.text(40, 205, "Bound Lua function: ON (F6 by default)",
            {120, 180, 255, 255})
    end
end)
