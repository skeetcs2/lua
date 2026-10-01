-- Persistent local kill counter with an adjustable shawarma icon.
local enabled = ui.create("checkbox", "shaurma_enabled", "Shaurma Hunter", false)
local icon_size = ui.create("slider", "shaurma_icon_size", "Icon size", 32, 16, 80)
local label_color = ui.create("color", "shaurma_color", "Text color", {255, 255, 255, 255})

local kills = storage.get("shaurma_kills", 0)
local icon, assets_loaded = nil, false

events.on("game_event", function(event)
    -- Lua API maps the local player to attacker == 0; userid is the victim.
    if event.name == "player_death" and event.attacker == 0 and event.userid ~= 0 then
        kills = kills + 1
        storage.set("shaurma_kills", kills)
    end
end)

events.on("paint", function()
    if not ui.get(enabled) then return end
    if not assets_loaded then
        icon = render.setup_texture("skeetles/shawa.png")
        assets_loaded = true
    end

    local size = ui.get(icon_size)
    local text = "SHAWA X " .. tostring(kills)
    local text_width = render.measure_text(text)
    local screen_width = render.screen_size()
    local gap, right_margin, y = 10, 22, 22
    local x = screen_width - right_margin - text_width - gap - size

    if icon then
        render.texture(icon, x, y, size, size, {255, 255, 255, 255})
    end
    render.text(x + size + gap, y + math.max(0, (size - 20) * 0.5), text, ui.get(label_color))
end)
