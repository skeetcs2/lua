-- Animate the built-in "skeet" watermark.
local enabled = ui.create("checkbox", "rgb_watermark_enabled", "RGB watermark", false)
local speed = ui.create("slider", "rgb_watermark_speed", "RGB speed", 1, 0.1, 5)
local applied = false

local function release()
    if not applied then return end
    settings.override("widgets", "watermark color", nil)
    applied = false
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    local phase = client.time() * ui.get(speed)
    local function channel(offset)
        return math.floor(127.5 + 127.5 * math.sin(phase + offset))
    end
    settings.override("widgets", "watermark color",
        {channel(0), channel(2.0944), channel(4.1888), 255})
    applied = true
end)

events.on("shutdown", release)
