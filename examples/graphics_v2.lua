-- API v2. All resource creation and drawing stay in paint.
local enabled = ui.create("checkbox", "enabled", "Graphics API demo", true)
local texture, attempted = nil, false
events.on("paint", function()
    if not ui.get(enabled) then return end
    if not attempted then
        attempted = true
        texture = render.setup_texture_rgba(string.char(255, 255, 255, 255), 1, 1)
    end
    render.push_clip_rect(25, 25, 300, 160)
    render.rect_filled_fade(30, 30, 270, 130,
        {35, 40, 60, 230}, {70, 40, 60, 230}, {30, 20, 25, 230}, {20, 30, 50, 230})
    render.arc(75, 85, 24, 0, client.time() % (2 * math.pi), {150, 220, 255, 255}, 2)
    render.concave_polygon({{x=140,y=60},{x=190,y=60},{x=165,y=85},{x=190,y=110},{x=140,y=110}},
        {170, 220, 130, 255})
    if texture then render.texture(texture, 210, 60, 60, 50, {220, 160, 240, 180}, 4) end
    render.text(40, 138, "Frame " .. tostring(render.frame_count()), {230, 230, 230, 255})
    render.pop_clip_rect()
end)
