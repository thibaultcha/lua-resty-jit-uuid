package = "lua-resty-jit-uuid"
version = "0.0.1-0"
source = {
  url = "https://github.com/thibaultCha/lua-resty-jit-uuid",
  tag = "0.0.1"
}
description = {
  summary = "Fast and dependency-free uuid generation for OpenResty/LuaJIT",
  detailed = [[
    This module is aimed at filling a gap between performant uuid generation and
    the libuuid requirement of FFI and C bindings. Its goal is to provide fast
    uuid generation, without dependencies for OpenResty and LuaJIT.

    It is a good candidate if you want a more performant generation than pure Lua,
    without depending on libuuid. It also provides very efficient uuid validation,
    using JIT PCRE if available in OpenResty, with a fallback on Lua patterns.
  ]],
  homepage = "https://github.com/thibaultCha/lua-resty-jit-uuid",
  license = "MIT"
}
build = {
  type = "builtin",
  modules = {
    ["resty.jit-uuid"] = "lib/resty/jit-uuid.lua"
  }
}
