-- A simple on-screen status label; it does not implement resolver logic.
local enabled = ui.create("checkbox", "resolver_label_enabled", "Skeet Resolver", false)
local color = ui.create("color", "resolver_label_color", "Label color", {120, 220, 140, 255})

events.on("paint", function()
    if not ui.get(enabled) then return end
    render.text(24, 24, "Skeet Resolver: Enable", ui.get(color))
end)
