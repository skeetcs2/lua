local enabled = ui.create("checkbox", "enabled", "Watermark", true)
local tint = ui.create("color", "tint", "Color", {220, 230, 255, 255})
events.on("paint", function()
    if not ui.get(enabled) then return end
    local w = client.screen_size()
    local text = "Lua API " .. api.version .. " | " .. api.script
    local width = render.measure_text(text)
    render.text(w - width - 20, 20, text, ui.get(tint))
end)
