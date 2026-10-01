-- Custom active keybind list using Excalifont-Regular.ttf from resources/.
local enabled = ui.create("checkbox", "custom_keybinds_enabled", "Custom keybinds", false)
local text_color = ui.create("color", "custom_keybinds_color", "Text color", {255, 255, 255, 255})
local font
local assets_loaded = false
local applied = false

local function release()
    if not applied then return end
    settings.override("widgets", "show keybinds", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    if not assets_loaded then
        font = render.setup_font("Excalifont-Regular.ttf", 16)
        assets_loaded = true
    end
    settings.override("widgets", "show keybinds", false)
    applied = true

    local width, height = render.screen_size()
    local x, y = 100, height * 0.5 + 34
    local count = 0
    render.text(x, y - 22, "KEYBINDS", ui.get(text_color), font)
    for _, bind in ipairs(settings.binds()) do
        if bind.active and bind.value then
            local row_y = y + count * 22
            render.circle(x + 5, row_y + 8, 3, {170, 200, 255, 255}, true)
            render.text(x + 16, row_y, bind.name, ui.get(text_color), font)
            count = count + 1
            if count >= 24 then break end
        end
    end
    -- Example of a Lua-owned row. Replace X and the label with your own action.
    if client.key_down(0x58) then
        local row_y = y + count * 22
        render.circle(x + 5, row_y + 8, 3, {170, 200, 255, 255}, true)
        render.text(x + 16, row_y, "My Lua action [X]", ui.get(text_color), font)
    end
end)

events.on("shutdown", release)
