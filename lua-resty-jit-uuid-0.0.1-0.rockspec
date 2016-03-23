package = "lua-resty-jit-uuid"
version = "0.0.1-0"
source = {
  url = "https://github.com/thibaultCha/lua-resty-jit-uuid",
  tag = "0.0.1"
}
description = {
  summary = "Fast and dependency-free uuid generation for LuaJIT",
  homepage = "https://github.com/thibaultCha/lua-resty-jit-uuid",
  license = "MIT"
}
build = {
  type = "builtin",
  modules = {
    ["resty.jit-uuid"] = "lib/resty/jit-uuid.lua"
  }
}
