-- Optional surface-impact rings. These are not player-hit hitmarkers.
local enabled = ui.create("checkbox", "rgb_markers_enabled", "Surface impact rings", false)
local rainbow = ui.create("checkbox", "rgb_markers_rainbow", "RGB markers", true)
local accent = ui.create("color", "rgb_markers_color", "Marker color", {110, 200, 255, 255})
local marks = {}

events.on("game_event", function(event)
    if event.name == "round_start" then marks = {}; return end
    if event.name ~= "bullet_impact" or not event.position or not ui.get(enabled) then return end
    local me = entity.local_player()
    if not me or event.userid ~= me.id then return end
    marks[#marks + 1] = {position = event.position, at = client.time()}
    if #marks > 12 then table.remove(marks, 1) end
end)

events.on("paint", function()
    local now = client.time()
    for i = #marks, 1, -1 do
        local mark = marks[i]
        local age = now - mark.at
        if age > 1.5 then
            table.remove(marks, i)
        elseif ui.get(enabled) then
            local x, y = render.world_to_screen(mark.position)
            if x then
                local phase = now * 2
                local color = ui.get(accent)
                if ui.get(rainbow) then
                    color = {
                        math.floor(127.5 + 127.5 * math.sin(phase)),
                        math.floor(127.5 + 127.5 * math.sin(phase + 2.0944)),
                        math.floor(127.5 + 127.5 * math.sin(phase + 4.1888)), 255
                    }
                end
                render.arc(x, y, 4 + age * 13, 0, 6.2832,
                    {color[1], color[2], color[3], math.floor(color[4] * (1 - age / 1.5))}, 2)
            end
        end
    end
end)
