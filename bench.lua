if not jit then
  error("must run in LuaJIT")
end

package.path = "lib/?.lua;"..package.path

local cuuid = require "lua_uuid"
local lua_uuid = require "uuid"
local ffi_uuid = require "resty.uuid"
local luajit_uuid = require "resty.jit-uuid"

local assert = assert
math.randomseed(os.time())

-------------
-- Generation
-------------
local res = {}
local uuids = {}
local n_uuids = 10^6
local tests = {
  ["Pure Lua"] = lua_uuid.new,
  ["Pure LuaJIT"]= luajit_uuid.generate,
  ["C binding"] = cuuid,
  ["FFI binding"] = ffi_uuid.generate_random
}

for k, uuid in pairs(tests) do
  local tstart = os.clock()
  for i = 1, n_uuids do
    uuid()
  end
  res[#res+1] = {module = k, time = os.clock() - tstart}
end

table.sort(res, function(a, b) return a.time < b.time end)

print(jit.version)
print(string.format("UUID generation (%g UUIDs)", n_uuids))
for i, result in ipairs(res) do
  print(string.format("%d. %s\ttook:\t%fs", i, result.module, result.time))
end

-------------
-- Validation
-------------

if ngx then -- running in resty-cli
  package.loaded["resty.jit-uuid"] = nil
  ngx.config.nginx_configure = function() return "" end
  local pattern_uuid = require "resty.jit-uuid"
  tests = {
    ["FFI binding"] = ffi_uuid.is_valid,
    ["Pure LuaJIT (JIT PCRE enabled)"] = luajit_uuid.is_valid,
    ["Pure LuaJIT (Lua patterns)"] = pattern_uuid.is_valid
  }
else
  tests = {
    ["FFI binding"] = ffi_uuid.is_valid,
    ["Pure LuaJIT (Lua patterns)"] = luajit_uuid.is_valid
  }
end

res = {}
for i = 1, n_uuids do
  uuids[i] = luajit_uuid() -- we need v4 uuids to validate with our module
end

for k, validate in pairs(tests) do
  local tstart = os.clock()
  for i = 1, n_uuids do
    assert(validate(uuids[i]))
  end
  res[#res+1] = {module = k, time = os.clock() - tstart}
end

table.sort(res, function(a, b) return a.time < b.time end)
print(string.format("\nUUID validation if provided (%g UUIDs)", n_uuids))
for i, result in ipairs(res) do
  print(string.format("%d. %s\ttook:\t%fs", i, result.module, result.time))
end
