-- Script-defined flat material for enemies. One Lua checkbox controls both layers.
local enabled = ui.create("checkbox", "custom_flat_chams", "Custom flat enemy chams", false)
local invisible = ui.create("checkbox", "custom_flat_xray", "Show through walls", false)
local pulse = ui.create("checkbox", "custom_flat_pulse", "Pulse color", true)
local material = chams.create_material(1.25, {180, 215, 255, 255})

local function clear()
    chams.set("enemy", nil)
    chams.set("enemy_invisible", nil)
end

events.on("paint", function()
    if not ui.get(enabled) then clear(); return end
    local alpha = ui.get(pulse) and math.floor(170 + 60 * math.sin(client.time() * 2)) or 220
    chams.set("enemy", material, {95, 165, 255, alpha})
    chams.set("enemy_invisible", ui.get(invisible) and material or nil,
        {255, 95, 160, 140})
end)

events.on("shutdown", clear)
