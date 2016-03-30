if not jit then
  error("must run in LuaJIT or resty-cli")
end

-------------
-- Settings
-------------
local n_uuids = 10^6
local p_valid_uuids = 70

package.path = "lib/?.lua;"..package.path

local cuuid = require "lua_uuid"
local lua_uuid = require "uuid"
local ffi_uuid = require "resty.uuid"
local luajit_uuid = require "resty.jit-uuid"

math.randomseed(os.time())

-------------
-- Generation
-------------
local tests = {
  ["Pure Lua"] = lua_uuid.new,
  ["Pure LuaJIT"]= luajit_uuid.generate,
  ["C binding"] = cuuid,
  ["FFI binding"] = ffi_uuid.generate_random
}

local gen_res = {}
local luajit_uuid_time
for k, uuid in pairs(tests) do
  local tstart = os.clock()
  for _ = 1, n_uuids do
    uuid()
  end
  local time = os.clock() - tstart
  gen_res[#gen_res+1] = {module = k, time = time}
  if k == "Pure LuaJIT" then
    luajit_uuid_time = time
  end
end

for _, res in ipairs(gen_res) do
  res.diff = ((res.time - luajit_uuid_time)/luajit_uuid_time)*100
end

table.sort(gen_res, function(a, b) return a.time < b.time end)

print(jit.version)
print(string.format("UUID generation (%g UUIDs)", n_uuids))
for i, result in ipairs(gen_res) do
  print(string.format("%d. %s\ttook:\t%fs\t%+d%%", i, result.module, result.time, result.diff))
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

local uuids = {}
local p_invalid_uuids = p_valid_uuids + (100 - p_valid_uuids) / 2
for i = 1, n_uuids do
  local r = math.random(0, 100)
  if r <= p_valid_uuids then
    uuids[i] = luajit_uuid() -- we need v4 uuids to validate with our module
  elseif r <= p_invalid_uuids then
    uuids[i] = "03111af4-f2ee-11e5-ba5e-43ddcc7efcdZ" -- invalid UUID
  else
    uuids[i] = "03111af4-f2ee-11e5-ba5e-43ddcc7efcd" -- invalid length
  end
end

local val_res = {}
for k, validate in pairs(tests) do
  local tstart = os.clock()
  local check = {}
  for i = 1, n_uuids do
    local ok = validate(uuids[i])
    check[ok] = true
  end
  -- make sure there is no false positives here
  if not check[true] or not check[false] then
    error("all validations have the same result for "..k)
  end
  val_res[#val_res+1] = {module = k, time = os.clock() - tstart}
end

table.sort(val_res, function(a, b) return a.time < b.time end)

print(string.format("\nUUID validation if supported (set of %d%% valid, %d%% invalid)",
  p_valid_uuids,
  100 - p_valid_uuids))
for i, result in ipairs(val_res) do
  print(string.format("%d. %s\ttook:\t%fs", i, result.module, result.time))
end
