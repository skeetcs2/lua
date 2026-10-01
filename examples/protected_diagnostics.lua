-- Ordinary errors have a fallback; execution limits still disable the script.
local enabled = ui.create("checkbox", "diagnostics_enabled", "Lua diagnostics", true)
local font, attempted

events.on("paint", function()
    if not ui.get(enabled) then return end
    if not attempted then
        attempted = true
        local reason
        font, reason = render.setup_font("Excalifont-Regular.ttf", 18)
        if not font then client.log_level("warning", "Font fallback:", reason) end
    end
    local ok, err, width, height = api.protect(function()
        return render.measure_text("Lua diagnostics", font)
    end, {instructions = 50000, time_ms = 2})
    if not ok then
        client.log_level("warning", err)
        return
    end
    local stats = client.stats()
    render.text(40, 40, "Lua diagnostics", {255,255,255,255}, font)
    render.text(40, 44 + height, string.format("%.0f x %.0f | %.2f ms | ~%d instructions",
        width, height, stats.time_ms, stats.instructions), {180,210,255,255}, font)
end)
