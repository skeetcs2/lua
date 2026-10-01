local enabled = ui.create("checkbox", "enabled", "Damage probe", false)
local result = nil
events.on("pre_rage", function()
    result = nil
    if not ui.get(enabled) or not combat.context().valid then return end
    local players = entity.players(true)
    local target = players[1]
    if not target then return end
    local point = entity.bone(target.id, 7)
    if not point then return end
    local hit = combat.damage(target.id, point)
    if hit then result = {point = point, damage = hit.damage} end
end)
events.on("paint", function()
    local me = entity.local_player()
    if not ui.get(enabled) or not result or not me or not me.alive then return end
    local x, y, visible = render.world_to_screen(result.point)
    if x and visible then
        render.text(x, y, string.format("Predicted: %.0f", result.damage), {255, 255, 255, 255})
    end
end)
events.on("game_event", function(e)
    if e.name == "round_start" then result = nil end
end)
