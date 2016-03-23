package = "lua-resty-pure-uuid"
version = "0.0.1-0"
source = {
  url = "https://github.com/thibaultCha/lua-resty-pure-uuid",
  tag = "0.0.1"
}
description = {
  summary = "Fast and dependency-free uuid generation for LuaJIT",
  homepage = "https://github.com/thibaultCha/lua-resty-pure-uuid",
  license = "MIT"
}
build = {
  type = "builtin",
  modules = {
    ["resty.pure-uuid"] = "lib/resty/pure-uuid.lua"
  }
}
