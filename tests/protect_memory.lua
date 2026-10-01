-- Expected: allocation rejected by the 32 MiB Lua allocator; script disabled.
-- api.protect must not turn it into a recoverable false/error result.
api.protect(function()
    return string.rep("x", 40 * 1024 * 1024)
end, {instructions = 2000000, time_ms = 25})
client.log_level("error", "FAILURE: allocation failure was swallowed")
