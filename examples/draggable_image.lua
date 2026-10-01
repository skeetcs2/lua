-- Put logo.png in %LOCALAPPDATA%/skeet/skeetles, or change this path.
local image_path = "skeetles/logo.png"
local enabled = ui.create("checkbox", "drag_image_enabled", "Screen image", true)
local image, image_w, image_h
local loaded = false
local x = storage.get("image_x", 120)
local y = storage.get("image_y", 120)
local dragging, grab_x, grab_y = false, 0, 0

events.on("paint", function()
    if not ui.get(enabled) then dragging = false; return end
    if not loaded then
        image = render.setup_texture(image_path)
        if image then image_w, image_h = render.texture_size(image) end
        loaded = true
    end
    if not image then return end

    if ui.is_menu_opened() then
        local mouse = ui.mouse_state()
        if mouse.clicked and mouse.x >= x and mouse.x <= x + image_w
            and mouse.y >= y and mouse.y <= y + image_h then
            dragging = true
            grab_x, grab_y = mouse.x - x, mouse.y - y
        end
        if dragging then
            if mouse.down then
                local screen_w, screen_h = render.screen_size()
                x = math.max(0, math.min(screen_w - image_w, mouse.x - grab_x))
                y = math.max(0, math.min(screen_h - image_h, mouse.y - grab_y))
            else
                dragging = false
                storage.set("image_x", x)
                storage.set("image_y", y)
            end
        end
    elseif dragging then
        dragging = false
        storage.set("image_x", x)
        storage.set("image_y", y)
    end
    render.texture(image, x, y, image_w, image_h)
end)
