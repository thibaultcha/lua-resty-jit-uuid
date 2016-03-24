--- jit-uuid
-- Fast and dependency-free uuid generation for OpenResty/LuaJIT.
-- @module jit-uuid
-- @author Thibault Charbonnier
-- @license MIT
-- @release 0.0.1

local bit = require 'bit'

local randomseed = math.randomseed
local concat = table.concat
local random = math.random
local match = string.match
local tohex = bit.tohex
local band = bit.band
local bor = bit.bor

local _M = {
  _VERSION = '0.0.1'
}

function _M.seed()
  if ngx then
    randomseed(ngx.time() + ngx.worker.pid())
  elseif package.loaded['socket'] and package.loaded['socket'].gettime then
    randomseed(package.loaded['socket'].gettime()*10000)
  else
    randomseed(os.time())
  end
end

local buf = {0,0,0,0,'-',0,0,'-',0,0,'-',0,0,'-',0,0,0,0,0,0}
local buf_len = #buf

--- Generate a v4 uuid.
-- @function generate
-- @treturn string `uuid`: a v4 (randomly generated) uuid.
-- @usage
-- local uuid = require "resty.jit-uuid"
--
-- local u1 = uuid() -- metatable
-- local u2 = uuid.generate()
local function generate()
  for i = 1, buf_len do
    if i ~= 9 and i ~= 12 then -- benchmarked
      buf[i] = tohex(random(0, 255), 2)
    end
  end

  buf[5], buf[8], buf[11], buf[14] = '-', '-', '-', '-' -- benchmarked
  buf[9] = tohex(bor(band(random(0, 255), 0x0F), 0x40), 2)
  buf[12] = tohex(bor(band(random(0, 255), 0x3F), 0x80), 2)

  return concat(buf)
end

_M.generate = generate

do
  local find = string.find
  if ngx and find(ngx.config.nginx_configure(),'--with-pcre-jit',nil,true) then
    local re_find = ngx.re.find
    local regex = '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'

    --- Validate v4 uuids.
    -- Only validates v4 uuids including dashes, version and variant.
    -- Use JIT PCRE if available in OpenResty or fallbacks on Lua pattern.
    -- @param[type=string] str String to verify.
    -- @treturn boolean `valid`: true if v4 uuid, false otherwise.
    -- @usage
    -- local uuid = require "resty.jit-uuid"
    --
    -- uuid.is_valid "cbb297c0-a956-486d-ad1d-f9bZZZZZZZZZ" --> false
    -- uuid.is_valid "cbb297c0-a956-586d-ad1d-f9b42df9465a" --> false (not v4)
    -- uuid.is_valid "cbb297c0-a956-486d-dd1d-f9b42df9465a" --> false (invalid variant)
    -- uuid.is_valid "cbb297c0a956486dad1df9b42df9465a"     --> false (no dashes)
    -- uuid.is_valid "cbb297c0-a956-486d-ad1d-f9b42df9465a" --> true
    _M.is_valid = function(str)
      -- it has proven itself efficient to first check the length with an
      -- evenly distributed set of valid and invalid uuid lengths.
      if #str ~= 36 then return false end
      return re_find(str, regex, 'oj') ~= nil
    end

  else
    local d = '[0-9a-f]'
    local p = '^'..concat({
                d:rep(8),
                d:rep(4),
           '4'..d:rep(3),
      '[89ab]'..d:rep(3),
                d:rep(12)
    }, '%-')..'$'

    _M.is_valid = function(str)
      if #str ~= 36 then return false end
      return match(str, p) ~= nil
    end

  end
end

return setmetatable(_M, {
  __call = function()
    return generate()
  end
})
