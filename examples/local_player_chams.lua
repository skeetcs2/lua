-- Local third-person model; it may not be visible in first-person view.
local enabled = ui.create("checkbox", "flat_local", "Flat local player", false)
local material = chams.create_material(0.8, {255, 240, 190, 255})

events.on("paint", function()
    chams.set("local", ui.get(enabled) and material or nil, {255, 210, 110, 220})
end)

events.on("shutdown", function() chams.set("local", nil) end)
