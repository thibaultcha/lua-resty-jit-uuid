# lua-resty-pure-uuid

A pure LuaJIT (no dependencies) uuid generator tuned for performance.

### Table of Contents

* [Motivation](#motivation)
* [Usage](#usage)
* [Installation](#installation)
* [Benchmarks](#benchmarks)
* [License](#license)

### Motivation

This module is aimed at filling a gap between performant uuid generation and
the libuuid requirement of FFI and C bindings. Its goal is to provide **fast**
uuid generation, **without dependencies** for OpenResty and LuaJIT.

It is a good candidate if you want a more performant generation than pure Lua,
without depending on libuuid.

See the [Benchmarks](#benchmarks) section for comparisons between other uuid
libraries for Lua/LuaJIT.

[Back to TOC](#table-of-contents)

### Usage

LuaJIT:
```lua
local uuid = require "resty.pure-uuid"

uuid.seed()     -- automatic seeding with os.time(), LuaSocket, or ngx.time()

uuid()          ---> uuid (with metatable lookup)
uuid.generate() ---> uuid
```

OpenResty:
```nginx
http {
    init_worker_by_lua_block {
        local uuid = require "resty.pure-uuid"
        uuid.seed() -- Very important!
    }

    server {
        location / {
            content_by_lua_block {
                local uuid = require "resty.pure-uuid"
                ngx.say(uuid())
            }
        }
    }
}
```

**Note**: when used in OpenResty, it is **very important** that you seed this
module in the `init_worker` phase. If you do not, your workers will generate
identical uuid sequences, which could lead to serious issues in your
application.

[Back to TOC](#table-of-contents)

### Installation

This module can be installed through Luarocks:
```bash
$ luarocks install lua-resty-pure-uuid
```

Or can be manually copied in your `LUA_PATH`.

[Back to TOC](#table-of-contents)

### Benchmarks

The `bench.lua` file provides benchmarks for several popular uuid libraries. As
expected, C and FFI bindings are the fastest, but this module still provides a
very reasonable performance at the cost of being free of dependencies.

Run `make bench` to run them:
```
LuaJIT 2.1.0-beta1
1e+06 uuids generated
1. FFI binding	took:	0.103862ms
2. C binding	took:	0.224119ms
3. Pure LuaJIT	took:	0.792812ms
4. Pure Lua	took:	2.139352ms
```

FFI binding: <https://github.com/bungle/lua-resty-uuid>
C binding: <https://github.com/Mashape/lua-uuid>
Pure Lua: <https://github.com/Tieske/uuid>
Pure LuaJIT: this module

[Back to TOC](#table-of-contents)

### License

Work licensed under the MIT License.

[Back to TOC](#table-of-contents)
