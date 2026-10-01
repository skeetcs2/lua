-- Run after the user builds. Tests the real native binding, not the offline mocks.
local limits = {instructions = 2000000, time_ms = 25}
local result = table.pack(api.protect(function() return 42, nil, "tail", nil end, limits))
assert(result.n == 6 and result[1] == true and result[2] == nil)
assert(result[3] == 42 and result[4] == nil and result[5] == "tail" and result[6] == nil)
assert(select("#", api.protect(function() end, limits)) == 2)
local many = {}
for i = 1, 256 do many[i] = i end
local packed = table.pack(api.protect(function() return table.unpack(many) end, limits))
assert(packed.n == 258 and packed[3] == 1 and packed[258] == 256)

local ok, err = api.protect(function() error("expected Lua error") end, limits)
assert(not ok and type(err) == "string" and err:find("expected Lua error", 1, true))
ok, err = api.protect(function() settings.get("__missing_category__", "__missing_setting__") end, limits)
assert(not ok and err:find("unknown setting", 1, true))
ok, err = api.protect(function() api.protect(function() end, {instructions = 0}) end, limits)
assert(not ok and err:find("instructions", 1, true))

local outer, outer_err, inner, inner_err, answer = api.protect(function()
    return api.protect(function() return 7 end, limits)
end, limits)
assert(outer and outer_err == nil and inner and inner_err == nil and answer == 7)
local stats = client.stats()
assert(stats.protected_errors >= 3 and stats.api_calls > 0 and stats.memory_bytes > 0)
assert(pcall == nil and xpcall == nil)
client.log("PASS: protected returns, nils, Lua/API errors, limits, nesting, stats")
client.unload()
