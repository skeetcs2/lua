local opacity = ui.create("slider", "opacity", "Opacity",
    storage.get("opacity", 200), 0, 255)
local last = ui.get(opacity)
events.on("paint", function()
    local current = ui.get(opacity)
    if current ~= last then
        storage.set("opacity", current)
        last = current
    end
    render.text(30, 110, "Persistent Lua UI", {255, 255, 255, math.floor(current)})
end)
