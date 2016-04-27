if not ngx or not jit then
  error('must run in resty-cli with LuaJIT')
end

-------------
-- Settings
-------------
local n_uuids = 10^6
local p_valid_uuids = 70

package.path = 'lib/?.lua;'..package.path

local cuuid = require 'lua_uuid'
local lua_uuid = require 'uuid'
local ffi_uuid = require 'resty.uuid'
local luajit_uuid = require 'resty.jit-uuid'
package.loaded['resty.jit-uuid'] = nil
ngx.config.nginx_configure = function() return '' end
local luajit_uuid_no_pcre = require 'resty.jit-uuid'

math.randomseed(os.time())

---------------------
-- UUID v4 generation
---------------------
local tests = {
  ['C binding     '] = cuuid,
  ['Pure Lua      '] = lua_uuid.new,
  ['resty-jit-uuid'] = luajit_uuid.generate_v4,
  ['FFI binding   '] = ffi_uuid.generate_random
}

local v4_results = {}
local time_reference
for k, uuid in pairs(tests) do
  collectgarbage()

  local tstart = os.clock()
  for _ = 1, n_uuids do
    uuid()
  end
  local time = os.clock() - tstart

  v4_results[#v4_results+1] = {module = k, time = time}
  if k == 'resty-jit-uuid' then
    time_reference = time
  end
end

for _, res in ipairs(v4_results) do
  res.diff = ((res.time - time_reference)/time_reference)*100
end

table.sort(v4_results, function(a, b) return a.time < b.time end)

print(string.format('%s with %g UUIDs', jit.version, n_uuids))
print('UUID v4 (random) generation')
for i, result in ipairs(v4_results) do
  print(string.format('%d. %s\ttook:\t%fs\t%+d%%', i, result.module, result.time, result.diff))
end

---------------------
-- UUID v3 generation
---------------------

-- unique names, unique namespaces: no strings interned
tests = {
  ['resty-jit-uuid'] = assert(luajit_uuid.factory_v3('cc7da0b0-0743-11e6-968a-bfd4d8c62f62'))
}
local names = {}
for i = 1, n_uuids do
  names[i] = ffi_uuid.generate_random()
end

local v3_results = {}
for k, factory in pairs(tests) do
  collectgarbage()

  local tstart = os.clock()
  local check = {}
  for i = 1, n_uuids do
    factory(names[i])
  end
  local time = os.clock() - tstart

  v3_results[#v3_results+1] = {module = k, time = time}
end

table.sort(v3_results, function(a, b) return a.time < b.time end)

print('\nUUID v3 (name-based and MD5) generation if supported')
for i, result in ipairs(v3_results) do
  print(string.format('%d. %s\ttook:\t%fs', i, result.module, result.time))
end

---------------------
-- UUID v5 generation
---------------------

-- unique names, unique namespaces: no strings interned
tests = {
  ['resty-jit-uuid'] = assert(luajit_uuid.factory_v5('1b985f4a-06be-11e6-aff4-ff8d14e25128'))
}
local names = {}
for i = 1, n_uuids do
  names[i] = ffi_uuid.generate_random()
end

local v5_results = {}
for k, factory in pairs(tests) do
  collectgarbage()

  local tstart = os.clock()
  local check = {}
  for i = 1, n_uuids do
    factory(names[i])
  end
  local time = os.clock() - tstart

  v5_results[#v5_results+1] = {module = k, time = time}
end

table.sort(v5_results, function(a, b) return a.time < b.time end)

print('\nUUID v5 (name-based and SHA-1) generation if supported')
for i, result in ipairs(v5_results) do
  print(string.format('%d. %s\ttook:\t%fs', i, result.module, result.time))
end

-------------
-- Validation
-------------
tests = {
  ['FFI binding                      '] = ffi_uuid.is_valid,
  ['resty-jit-uuid (JIT PCRE enabled)'] = luajit_uuid.is_valid,
  ['resty-jit-uuid (Lua patterns)    '] = luajit_uuid_no_pcre.is_valid
}

local uuids = {}
local p_invalid_uuids = p_valid_uuids + (100 - p_valid_uuids) / 2
for i = 1, n_uuids do
  local r = math.random(0, 100)
  if r <= p_valid_uuids then
    uuids[i] = ffi_uuid.generate_random()
  elseif r <= p_invalid_uuids then
    uuids[i] = '03111af4-f2ee-11e5-ba5e-43ddcc7efcdZ' -- invalid UUID
  else
    uuids[i] = '03111af4-f2ee-11e5-ba5e-43ddcc7efcd' -- invalid length
  end
end

local valid_results = {}
for k, validate in pairs(tests) do
  collectgarbage()
  local tstart = os.clock()
  local check = {}
  for i = 1, n_uuids do
    local ok = validate(uuids[i])
    check[ok] = true
  end
  -- make sure there is no false positives here
  if not check[true] or not check[false] then
    error('all validations have the same result for '..k)
  end
  valid_results[#valid_results+1] = {module = k, time = os.clock() - tstart}
end

table.sort(valid_results, function(a, b) return a.time < b.time end)

print(string.format('\nUUID validation if supported (set of %d%% valid, %d%% invalid)',
  p_valid_uuids,
  100 - p_valid_uuids))
for i, result in ipairs(valid_results) do
  print(string.format('%d. %s\ttook:\t%fs', i, result.module, result.time))
end
