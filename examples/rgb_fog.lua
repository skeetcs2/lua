-- Cycle the weather fog through RGB colors.
local enabled = ui.create("checkbox", "rgb_fog_enabled", "Looping RGB fog", false)
local speed = ui.create("slider", "rgb_fog_speed", "RGB speed", 1, 0.1, 5)

local function release()
    settings.override("weather", "fog", nil)
    settings.override("weather", "fog color", nil)
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
    settings.override("weather", "fog", true)
    settings.override("weather", "fog color",
        {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), 255})
end)

events.on("shutdown", release)
