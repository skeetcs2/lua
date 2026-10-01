-- Cycle the Falling Sperm particle tint through RGB colors.
local enabled = ui.create("checkbox", "rgb_sperm_enabled", "Looping RGB sperm", false)
local speed = ui.create("slider", "rgb_sperm_speed", "RGB speed", 1, 0.1, 5)

local function release()
    settings.override("weather", "weather", nil)
    settings.override("weather", "color", nil)
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
    settings.override("weather", "weather", true)
    settings.override("weather", "color",
        {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), 255})
end)

events.on("shutdown", release)
