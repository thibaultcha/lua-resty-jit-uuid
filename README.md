# lua-resty-jit-uuid

[![Module Version][badge-version-image]][luarocks-resty-jit-uuid]
[![Build Status][badge-travis-image]][badge-travis-url]

A pure LuaJIT (no dependencies) uuid generator tuned for performance.

### Table of Contents

* [Motivation](#motivation)
* [Usage](#usage)
* [Installation](#installation)
* [Documentation](#documentation)
* [Benchmarks](#benchmarks)
* [License](#license)

### Motivation

This module is aimed at filling a gap between performant uuid generation and
the libuuid requirement of FFI and C bindings. Its goal is to provide **fast**
uuid generation, **without dependencies** for OpenResty and LuaJIT.

It is a good candidate if you want a more performant generation than pure Lua,
without depending on libuuid. It also provides very efficient uuid validation,
using JIT PCRE if available in OpenResty, with a fallback on Lua patterns.

See the [Benchmarks](#benchmarks) section for comparisons between other uuid
libraries for Lua/LuaJIT.

[Back to TOC](#table-of-contents)

### Usage

LuaJIT:
```lua
local uuid = require "resty.jit-uuid"

uuid.seed()       -- automatic seeding with os.time(), LuaSocket, or ngx.time()

uuid()            ---> uuid (with metatable lookup)
uuid.generate()   ---> uuid

uuid.is_valid("") ---> true/false (automatic JIT PCRE or Lua patterns)
```

OpenResty:
```nginx
http {
    init_worker_by_lua_block {
        local uuid = require "resty.jit-uuid"
        uuid.seed() -- Very important!
    }

    server {
        location / {
            content_by_lua_block {
                local uuid = require "resty.jit-uuid"
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
$ luarocks install lua-resty-jit-uuid
```

Or can be manually copied in your `LUA_PATH`.

[Back to TOC](#table-of-contents)

### Documentation

Documentation is available online at
<http://thibaultcha.github.io/lua-resty-jit-uuid/>.

[Back to TOC](#table-of-contents)

### Benchmarks

This module has been carefully benchmarked on each step of its implementation
to ensure the best performance for OpenResty and plain LuaJIT. For example,
uuid validation will use JIT PCRE over Lua patterns if available, to ensure the
best performance.

The `bench.lua` file provides benchmarks of uuid generation for several popular
uuid libraries. As expected, C and FFI bindings are the fastest, but this
module still provides a very reasonable performance at the cost of being free
of dependencies.

Run `make bench` to run them:
```
LuaJIT 2.1.0-beta1
UUID generation (1e+06 UUIDs)
1. FFI binding took: 0.095588s -86%
2. C binding   took: 0.234322s -66%
3. Pure LuaJIT took: 0.703376s +0%
4. Pure Lua    took: 1.908608s +171%

UUID validation if provided (set of 70% valid, 30% invalid)
1. Pure LuaJIT (JIT PCRE enabled) took: 0.245202s
2. FFI binding                    took: 0.328822s
3. Pure LuaJIT (Lua patterns)     took: 0.557272s
```

* FFI binding: <https://github.com/bungle/lua-resty-uuid>
* C binding: <https://github.com/Mashape/lua-uuid>
* Pure Lua: <https://github.com/Tieske/uuid>
* Pure LuaJIT: this module (base reference for generation % comparison)

[Back to TOC](#table-of-contents)

### License

Work licensed under the MIT License.

[Back to TOC](#table-of-contents)

[luarocks-resty-jit-uuid]: http://luarocks.org/modules/thibaultcha/lua-resty-jit-uuid

[badge-travis-url]: https://travis-ci.org/thibaultCha/lua-resty-jit-uuid
[badge-travis-image]: https://travis-ci.org/thibaultCha/lua-resty-jit-uuid.svg?branch=master
[badge-version-image]: https://img.shields.io/badge/version-0.0.2-blue.svg?style=flat

