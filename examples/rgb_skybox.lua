-- Cycle the skybox tint through RGB colors.
local enabled = ui.create("checkbox", "aa_rgb_sky", "Looping RGB skybox", false)
local speed = ui.create("slider", "aa_rgb_speed", "RGB speed", 1, 0.1, 5)
local floor = ui.create("slider", "aa_rgb_floor", "RGB minimum light", 50, 0, 200)

local function release_sky()
    settings.override("scene", "skybox color", nil)
    settings.override("scene", "skybox color value", nil)
end

events.on("paint", function()
    if not ui.get(enabled) then
        release_sky()
        return
    end

    local phase = client.time() * ui.get(speed)
    local minimum = ui.get(floor)
    local range = 255 - minimum
    local function channel(shift)
        return math.floor(minimum + range * (0.5 + 0.5 * math.sin(phase + shift)))
    end
    settings.override("scene", "skybox color", true)
    settings.override("scene", "skybox color value",
        {channel(0), channel(2 * math.pi / 3), channel(4 * math.pi / 3), 255})
end)

events.on("shutdown", release_sky)
