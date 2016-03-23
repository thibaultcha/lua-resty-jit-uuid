if not jit then
  error("must run in LuaJIT")
end

package.path = "lib/?.lua;"..package.path

--local luuid = require "luuid"
local cuuid = require "lua_uuid" -- C binding
local lua_uuid = require "uuid" -- pure Lua
local ffi_uuid = require "resty.uuid" -- FFI binding
local luajit_uuid = require "resty.jit-uuid" -- Pure LuaJIT

math.randomseed(os.time())

local res = {}
local n_uuids = 10^6
local tests = {
  ["Pure Lua"] = lua_uuid.new,
  ["Pure LuaJIT"]= luajit_uuid.generate,
  --luuid = luuid.new,
  ["C binding"] = cuuid,
  ["FFI binding"] = ffi_uuid.generate
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
print(string.format("%g uuids generated", n_uuids))
for i, result in ipairs(res) do
  print(string.format("%d. %s\ttook:\t%fms", i, result.module, result.time))
end
