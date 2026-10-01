-- Replace the native world hitmarker with soufiw original.png.
-- Put the PNG in %LOCALAPPDATA%/skeet/skeetles.
local enabled = ui.create("checkbox", "soufiw_hitmarker_enabled", "Soufiw world hitmarker", true)
local size = ui.create("slider", "soufiw_hitmarker_size", "Image size", 48, 12, 160)
local duration = ui.create("slider", "soufiw_hitmarker_duration", "Visible seconds", 1, 0.2, 3)
local tint = ui.create("color", "soufiw_hitmarker_tint", "Image tint", {255, 255, 255, 255})

local image, source_w, source_h, loaded = nil, nil, nil, false
local applied = false
local impacts, markers = {}, {}

local function release()
    if applied then
        settings.override("impacts", "hitmarkers", nil)
        applied = false
    end
end

events.on("game_event", function(event)
    if not ui.get(enabled) then return end
    local now = client.time()
    if event.name == "bullet_impact" and event.userid == 0 and event.position then
        impacts[#impacts + 1] = {position = event.position, at = now}
        if #impacts > 24 then table.remove(impacts, 1) end
    elseif event.name == "player_hurt" and event.attacker == 0
        and event.userid ~= nil and event.userid ~= 0 then
        local victim = entity.get(event.userid)
        local origin = victim and victim.origin
        local best_index, best_distance = nil, nil
        for i = #impacts, 1, -1 do
            local impact = impacts[i]
            if now - impact.at <= 0.4 then
                local distance = 0
                if origin then
                    local p = impact.position
                    local dx, dy, dz = p.x - origin.x, p.y - origin.y, p.z - origin.z
                    distance = dx * dx + dy * dy + dz * dz
                end
                if not best_distance or distance < best_distance then
                    best_index, best_distance = i, distance
                end
            end
        end
        local position
        if best_index then
            position = table.remove(impacts, best_index).position
        elseif origin then
            position = {x = origin.x, y = origin.y, z = origin.z + 45}
        end
        if position then
            markers[#markers + 1] = {position = position, at = now}
            if #markers > 16 then table.remove(markers, 1) end
        end
    elseif event.name == "round_start" then
        impacts, markers = {}, {}
    end
end)

events.on("paint", function()
    if not ui.get(enabled) then
        impacts, markers = {}, {}
        release()
        return
    end
    if not loaded then
        loaded = true
        image = render.setup_texture("skeetles/soufiw original.png")
        if image then
            source_w, source_h = render.texture_size(image)
        else
            client.log("Soufiw hitmarker: missing skeetles/soufiw original.png")
        end
    end
    if not image then release(); return end

    settings.override("impacts", "hitmarkers", false)
    applied = true

    local now = client.time()
    for i = #impacts, 1, -1 do
        if now - impacts[i].at > 0.4 then table.remove(impacts, i) end
    end
    local lifetime = ui.get(duration)
    local side = ui.get(size)
    local factor = side / math.max(source_w, source_h)
    local w, h = source_w * factor, source_h * factor
    local color = ui.get(tint)
    for i = #markers, 1, -1 do
        local marker = markers[i]
        local age = now - marker.at
        if age >= lifetime then
            table.remove(markers, i)
        else
            local sx, sy, on_screen = render.world_to_screen(marker.position)
            if sx and on_screen then
                local alpha = math.floor(color[4] * (1 - age / lifetime))
                render.texture(image, sx - w * 0.5, sy - h * 0.5, w, h,
                    {color[1], color[2], color[3], alpha})
            end
        end
    end
end)

events.on("shutdown", release)
