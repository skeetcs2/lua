-- Expected: script disabled with budget error; the FAILURE line must never run.
-- An outer protect cannot catch the exhausted inner budget.
api.protect(function()
    local ok = api.protect(function()
        while true do end
    end, {instructions = 1000, time_ms = 25})
    client.log_level("error", "FAILURE: inner exhaustion was swallowed", ok)
end, {instructions = 2000000, time_ms = 25})
client.log_level("error", "FAILURE: outer exhaustion was swallowed")
