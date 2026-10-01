-- Expected: script disabled. Many short calls must consume the shared budget.
while true do
    api.protect(function() return 1 end, {instructions = 2000000, time_ms = 25})
end
