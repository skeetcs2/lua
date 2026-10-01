-- Cycle native ESP colors for enemy boxes, names, health and ammo.
-- The requested ESP elements are enabled only while this script is enabled.
local enabled = ui.create("checkbox", "rgb_esp_enabled", "RGB ESP: box, name, health, ammo", false)
local speed = ui.create("slider", "rgb_esp_speed", "RGB speed", 1, 0.1, 5)
local applied = false

local function color(time, alpha)
    local phase = time * ui.get(speed)
    local function channel(offset)
        return math.floor(127.5 + 127.5 * math.sin(phase + offset))
    end
    return {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), alpha}
end

local function write(category, name, value)
    settings.override(category, name, value)
end

local function release()
    if not applied then return end
    write("esp enemy", "esp overlay", nil)
    write("esp enemy box", "bounding box", nil)
    write("esp enemy box", "VISIBLE", nil)
    write("esp enemy health", "health bar", nil)
    write("esp enemy health", "VISIBLE", nil)
    write("esp enemy ammo", "ammo bar", nil)
    write("esp enemy ammo", "VISIBLE", nil)
    write("esp enemy name", "name", nil)
    write("esp enemy name", "color", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    local now = client.time()
    write("esp enemy", "esp overlay", true)
    write("esp enemy box", "bounding box", true)
    write("esp enemy box", "VISIBLE", color(now, 255))
    write("esp enemy health", "health bar", true)
    write("esp enemy health", "VISIBLE", color(now + 0.4, 255))
    write("esp enemy ammo", "ammo bar", true)
    write("esp enemy ammo", "VISIBLE", color(now + 0.8, 255))
    write("esp enemy name", "name", true)
    write("esp enemy name", "color", color(now + 1.2, 255))
    applied = true
end)

events.on("shutdown", release)
