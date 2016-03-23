local bit = require "bit"

local concat = table.concat
local randomseed = math.randomseed
local random = math.random
local tohex = bit.tohex
local band = bit.band
local bor = bit.bor

local _M = {}

local buf = {0,0,0,0,"-",0,0,"-",0,0,"-",0,0,"-",0,0,0,0,0,0}
local buf_len = #buf

function _M.seed()
  if ngx then
    randomseed(ngx.time() + ngx.worker.pid())
  elseif package.loaded["socket"] and package.loaded["socket"].gettime then
    randomseed(package.loaded["socket"].gettime()*10000)
  else
    randomseed(os.time())
  end
end

local function generate()
  for i = 1, buf_len do
    if i ~= 9 and i ~= 12 then
      buf[i] = tohex(random(0, 255), 2)
    end
  end

  buf[5], buf[8], buf[11], buf[14] = "-", "-", "-", "-"
  buf[9] = tohex(bor(band(random(0, 255), 0x0F), 0x40), 2)
  buf[12] = tohex(bor(band(random(0, 255), 0x3F), 0x80), 2)

  return concat(buf)
end

_M.generate = generate

return setmetatable(_M, {
  __call = function()
    return generate()
  end
})
