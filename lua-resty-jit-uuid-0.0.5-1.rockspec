package = "lua-resty-jit-uuid"
version = "0.0.5-1"
source = {
  url = "git://github.com/thibaultcha/lua-resty-jit-uuid",
  tag = "0.0.5"
}
description = {
  summary = "Fast and dependency-free uuid generation for OpenResty/LuaJIT",
  detailed = [[
    This module is aimed at being a free of dependencies, performant and
    complete UUID library for LuaJIT and ngx_lua.

    Unlike FFI and C bindings, it does not depend on libuuid being available
    in your system. On top of that, it performs **better** than most (all?)
    of the generators it was benchmarked against, FFI bindings included.

    Finally, it provides additional features such as UUID v3/v4 generation and
    UUID validation.
  ]],
  homepage = "http://thibaultcha.github.io/lua-resty-jit-uuid/",
  license = "MIT"
}
build = {
  type = "builtin",
  modules = {
    ["resty.jit-uuid"] = "lib/resty/jit-uuid.lua"
  }
}
