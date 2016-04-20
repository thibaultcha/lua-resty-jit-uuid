--- jit-uuid
-- Fast and dependency-free uuid generation for OpenResty/LuaJIT.
-- @module jit-uuid
-- @author Thibault Charbonnier
-- @license MIT
-- @release 0.0.2

local bit = require 'bit'

local _M = {
  _VERSION = '0.0.2'
}

local ngx_pcre = ngx and string.find(ngx.config.nginx_configure(),'--with-pcre-jit',nil,true)

----------
-- seeding
----------

function _M.seed()
  if ngx then
    math.randomseed(ngx.time() + ngx.worker.pid())
  elseif package.loaded['socket'] and package.loaded['socket'].gettime then
    math.randomseed(package.loaded['socket'].gettime()*10000)
  else
    math.randomseed(os.time())
  end
end

-------------
-- validation
-------------

do
  if ngx_pcre then
    local re_find = ngx.re.find
    local regex = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'

    --- Validate a string as a UUID.
    -- To be considered valid, a UUID must be given in its canonical
    -- form (hexadecimal digits including the hyphen characters).
    -- This function validates UUIDs disregarding their generation algorithm,
    -- but checks the variant field.
    --
    -- Use JIT PCRE if available in OpenResty or fallbacks on Lua patterns.
    --
    -- @param[type=string] str String to verify.
    -- @treturn boolean `valid`: true if valid UUID, false otherwise.
    -- @usage
    -- local uuid = require 'resty.jit-uuid'
    --
    -- uuid.is_valid 'cbb297c0-a956-486d-ad1d-f9bZZZZZZZZZ' --> false
    -- uuid.is_valid 'cbb297c0-a956-486d-dd1d-f9b42df9465a' --> false (invalid variant)
    -- uuid.is_valid 'cbb297c0a956486dad1df9b42df9465a'     --> false (no dashes)
    -- uuid.is_valid 'cbb297c0-a956-486d-ad1d-f9b42df9465a' --> true
    function _M.is_valid(str)
      -- it has proven itself efficient to first check the length with an
      -- evenly distributed set of valid and invalid uuid lengths.
      if #str ~= 36 then return false end
      return re_find(str, regex, 'oj') ~= nil
    end

  else
    local match = string.match
    local d = '[0-9a-f]'
    local p = '^'..table.concat({
                d:rep(8),
                d:rep(4),
                d:rep(4),
      '[89ab]'..d:rep(3),
                d:rep(12)
    }, '%-')..'$'

    function _M.is_valid(str)
      if #str ~= 36 then return false end
      return match(str, p) ~= nil
    end

  end
end

----------------
-- v4 generation
----------------

do
  local concat = table.concat
  local random = math.random
  local tohex = bit.tohex
  local band = bit.band
  local bor = bit.bor
  local buf = {0,0,0,0,'-',0,0,'-',0,0,'-',0,0,'-',0,0,0,0,0,0}
  local buf_len = #buf

  --- Generate a v4 UUID.
  -- v4 UUIDs are created from randomly generated numbers.
  --
  -- @treturn string `uuid`: a v4 (randomly generated) UUID.
  -- @usage
  -- local uuid = require 'resty.jit-uuid'
  --
  -- local u1 = uuid()             ---> __call metamethod
  -- local u2 = uuid.generate_v4()
  function _M.generate_v4()
    for i = 1, buf_len do
      if i ~= 9 and i ~= 12 and i ~= 5 and i ~= 8 and i ~= 11 and i ~= 14 then
        buf[i] = tohex(random(0, 255), 2)
      end
    end

    buf[9] = tohex(bor(band(random(0, 255), 0x0F), 0x40), 2)
    buf[12] = tohex(bor(band(random(0, 255), 0x3F), 0x80), 2)

    return concat(buf)
  end
end

----------------
-- v3 generation
----------------

do
  if ngx_pcre then
    local re_gmatch = ngx.re.gmatch
    local tonumber = tonumber
    local char = string.char
    local tohex = bit.tohex
    local band = bit.band
    local type = type
    local bor = bit.bor
    local md5 = ngx.md5
    local fmt = string.format
    local sub = string.sub

    --- Generate a v3 UUID factory.
    -- Creates a closure generating namespaced v3 UUIDs.
    --
    -- @param[type=string] namespace (must be a valid UUID according to `is_valid`)
    -- @treturn function `factory`: a v3 UUID generator.
    -- @treturn string `err`: a string describing an error
    -- @usage
    -- local uuid = require 'resty.jit-uuid'
    --
    -- local fact = assert(uuid.factory_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d'))
    --
    -- local u1 = fact('hello')
    -- ---> 3db7a435-8c56-359d-a563-1b69e6802c78
    --
    -- local u2 = fact('foobar')
    -- ---> e8d3eeba-7723-3b72-bbc5-8f598afa6773
    local function factory_v3(namespace)
      if not _M.is_valid(namespace) then
        return nil, 'invalid namespace'
      end

      local iter, err = re_gmatch(namespace, '([0-9a-z]{2})', 'ioj')
      if not iter then return nil, err end

      local binary = ''
      while true do
        local m, err = iter()
        if err then return nil, err
        elseif not m then break end

        binary = binary..char(tonumber(m[0], 16))
      end

      return function(name)
        if type(name) ~= 'string' then
          return nil, 'invalid name'
        end

        local hash = md5(binary..name)
        local version = tohex(bor(band(tonumber(sub(hash, 13, 14), 16), 0x0F), 0x30), 2)
        local variant = tohex(bor(band(tonumber(sub(hash, 17, 18), 16), 0x3F), 0x80), 2)

        return fmt('%s-%s-%s%s-%s%s-%s', sub(hash, 1, 8),
                                         sub(hash, 9, 12),
                                         version,
                                         sub(hash, 15, 16),
                                         variant,
                                         sub(hash, 19, 20),
                                         sub(hash, 21, 32))
      end
    end

    _M.factory_v3 = factory_v3

    --- Generate a v3 UUID.
    -- v3 UUIDs are created from a namespace and a name (a UUID and a string).
    -- The same name and namespace result in the same UUID. The same name and
    -- different namespaces result in different UUIDs, and vice-versa.
    --
    -- This is a sugar function which instanciates a short-lived v3 UUID factory.
    -- It is an expensive operation, and intensive generation using the same
    -- namespaces should prefer allocating their own long-lived factory with
    -- `factory_v3`.
    --
    -- @param[type=string] namespace (must be a valid UUID according to `is_valid`)
    -- @param[type=string] name
    -- @treturn string `uuid`: a v3 (namespaced) UUID.
    -- @treturn string `err`: a string describing an error
    -- @usage
    -- local uuid = require 'resty.jit-uuid'
    --
    -- local u = uuid.generate_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d', 'hello')
    -- ---> 3db7a435-8c56-359d-a563-1b69e6802c78
    function _M.generate_v3(namespace, name)
      local fact, err = factory_v3(namespace)
      if not fact then return nil, err end

      return fact(name)
    end

  else

  end
end


return setmetatable(_M, {
  __call = _M.generate_v4
})

