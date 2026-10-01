local enabled = ui.create("checkbox", "enabled", "Custom ESP", true)
local tint = ui.create("color", "tint", "Enemy color", {255, 180, 100, 230})
events.on("paint", function()
    if not ui.get(enabled) then return end
    for _, player in ipairs(entity.players(true)) do
        local box = entity.bounds(player.id)
        if box then
            render.rect(box.x, box.y, box.w, box.h, ui.get(tint))
            render.text(box.x, box.y - 18,
                player.name .. " | " .. player.health .. " HP", ui.get(tint))
        end
    end
end)
