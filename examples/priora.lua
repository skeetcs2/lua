-- Put image_2305.png in %LOCALAPPDATA%/skeet/skeetles.
local image_path = "skeetles/image_2305.png"
local enabled = ui.create("checkbox", "drag_priora_enabled", "Priora image", true)
local scale = ui.create("slider", "drag_priora_scale", "Image size (%)", 100, 10, 300)
local image, original_w, original_h
local loaded = false
local x = storage.get("priora_x", 120)
local y = storage.get("priora_y", 120)
local dragging, grab_x, grab_y = false, 0, 0

events.on("paint", function()
    if not ui.get(enabled) then dragging = false; return end
    if not loaded then
        image = render.setup_texture(image_path)
        if image then original_w, original_h = render.texture_size(image) end
        loaded = true
    end
    if not image then return end

    local factor = ui.get(scale) / 100
    local width, height = original_w * factor, original_h * factor
    if ui.is_menu_opened() then
        local mouse = ui.mouse_state()
        if mouse.clicked and mouse.x >= x and mouse.x <= x + width
            and mouse.y >= y and mouse.y <= y + height then
            dragging = true
            grab_x, grab_y = mouse.x - x, mouse.y - y
        end
        if dragging then
            if mouse.down then
                local screen_w, screen_h = render.screen_size()
                x = math.max(0, math.min(screen_w - width, mouse.x - grab_x))
                y = math.max(0, math.min(screen_h - height, mouse.y - grab_y))
            else
                dragging = false
                storage.set("priora_x", x)
                storage.set("priora_y", y)
            end
        end
    elseif dragging then
        dragging = false
        storage.set("priora_x", x)
        storage.set("priora_y", y)
    end
    render.texture(image, x, y, width, height)
end)
