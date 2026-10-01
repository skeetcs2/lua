-- Animate only the built-in hitmarker color. Tracer settings are independent.
local enabled = ui.create("checkbox", "rgb_hitmarkers_enabled", "RGB hitmarkers", false)
local speed = ui.create("slider", "rgb_hitmarkers_speed", "RGB speed", 1, 0.1, 5)

local function release()
    settings.override("impacts", "hitmarkers", nil)
    settings.override("impacts", "hitmarker color", nil)
end

events.on("paint", function()
    if not ui.get(enabled) then
        release()
        return
    end

    local phase = client.time() * ui.get(speed)
    local function channel(shift)
        return math.floor(127.5 + 127.5 * math.sin(phase + shift))
    end
    settings.override("impacts", "hitmarkers", true)
    settings.override("impacts", "hitmarker color",
        {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), 255})
end)

events.on("shutdown", release)
