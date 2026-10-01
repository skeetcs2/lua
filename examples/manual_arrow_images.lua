-- Put fluttershy.png in %LOCALAPPDATA%/skeet/skeetles.
-- Change these two paths to choose different images independently.
local left_path = "skeetles/fluttershy.png"
local right_path = "skeetles/fluttershy.png"
local enabled = ui.create("checkbox", "manual_images_enabled", "Manual images", false)
local image_size = ui.create("slider", "manual_images_size", "Image size", 24, 8, 96)
local left, right
local loaded = false

local function release()
    settings.override("anti aim", "manual left arrow", nil)
    settings.override("anti aim", "manual right arrow", nil)
end

events.on("paint", function()
    if not ui.get(enabled) then release(); return end
    if not loaded then
        left = render.setup_texture(left_path)
        right = render.setup_texture(right_path)
        loaded = true
    end
    if left then settings.override("anti aim", "manual left arrow", false) end
    if right then settings.override("anti aim", "manual right arrow", false) end

    if not settings.get("manual arrows", "anti aim") then return end
    local screen_w, screen_h = render.screen_size()
    local spacing = settings.get("anti aim", "manual arrow distance")
    local size = ui.get(image_size)
    local y = screen_h * 0.5 - size * 0.5
    if left and settings.get("manual left", "anti aim") then
        render.texture(left, screen_w * 0.5 - spacing * 0.5 - size * 0.5, y, size, size)
    end
    if right and settings.get("manual right", "anti aim") then
        render.texture(right, screen_w * 0.5 + spacing * 0.5 - size * 0.5, y, size, size)
    end
end)

events.on("shutdown", release)
