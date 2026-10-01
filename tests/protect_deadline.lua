-- Expected: script disabled with budget error even though fn is short.
-- A larger inner deadline must not extend the enclosing deadline.
api.protect(function()
    api.protect(function() return 1 end, {instructions = 2000000, time_ms = 25})
end, {instructions = 2000000, time_ms = 0.000001})
client.log_level("error", "FAILURE: enclosing deadline was extended")
