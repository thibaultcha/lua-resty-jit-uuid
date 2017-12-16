# lua-resty-jit-uuid

[![Module Version][badge-version-image]][luarocks-resty-jit-uuid]
[![Build Status][badge-travis-image]][badge-travis-url]
[![Coverage Status][badge-coveralls-image]][badge-coveralls-url]

A pure LuaJIT (no dependencies) UUID library tuned for performance.

### Table of Contents

* [Motivation](#motivation)
* [Usage](#usage)
* [Installation](#installation)
* [Documentation](#documentation)
* [Benchmarks](#benchmarks)
* [Contributions](#contributions)
* [License](#license)

### Motivation

This module is aimed at being a free of dependencies, performant and
complete UUID library for LuaJIT and ngx_lua.

Unlike FFI and C bindings, it does not depend on libuuid being available
in your system. On top of that, it performs **better** than most (all?)
of the generators it was benchmarked against, FFI bindings included.

Finally, it provides additional features such as UUID v3/v4/v5 generation and
UUID validation.

See the [Benchmarks](#benchmarks) section for comparisons between other UUID
libraries for Lua/LuaJIT.

[Back to TOC](#table-of-contents)

### Usage

LuaJIT:
```lua
local uuid = require 'resty.jit-uuid'

uuid.seed()        ---> automatic seeding with os.time(), LuaSocket, or ngx.time()

uuid()             ---> v4 UUID (random)
uuid.generate_v4() ---> v4 UUID

uuid.generate_v3() ---> v3 UUID (name-based with MD5)
uuid.generate_v5() ---> v5 UUID (name-based with SHA-1)

uuid.is_valid()    ---> true/false (automatic JIT PCRE or Lua patterns)
```

OpenResty:
```nginx
http {
    init_worker_by_lua_block {
        local uuid = require 'resty.jit-uuid'
        uuid.seed() -- very important!
    }

    server {
        location / {
            content_by_lua_block {
                local uuid = require 'resty.jit-uuid'
                ngx.say(uuid())
            }
        }
    }
}
```

**Note**: when generating v4 (random) UUIDs in ngx_lua, it is **very
important** that you seed this module in the `init_worker` phase. If you do
not, your workers will generate identical UUID sequences, which could lead to
serious issues in your application. The seeding requirement also applies in
uses outside of ngx_lua, although seeding is less delicate in such cases.
Additionally, you should be weary about the usage of the
[`lua_code_cache`](https://github.com/openresty/lua-nginx-module#lua_code_cache)
directive: if Lua code cache is disabled, all sequences of UUIDs generated
during subsequent requests will be identical, unless this module is seeded for
every request. Just like disabling Lua code cache, such behavior would be
considered an ngx_lua anti-pattern and you should avoid it.

[Back to TOC](#table-of-contents)

### Installation

This module can be installed through Luarocks:
```bash
$ luarocks install lua-resty-jit-uuid
```

Or via [opm](https://github.com/openresty/opm):
```bash
$ opm get thibaultcha/lua-resty-jit-uuid
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
UUID validation will use JIT PCRE over Lua patterns when possible.

The `bench.lua` file provides benchmarks of UUID generation for several popular
UUID libraries.

Run `make bench` to run them:
```
LuaJIT 2.1.0-beta1 with 1e+06 UUIDs
UUID v4 (random) generation
1. resty-jit-uuid   took:   0.064228s    0%
2. FFI binding      took:   0.093374s   +45%
3. C binding        took:   0.220542s   +243%
4. Pure Lua         took:   2.051905s   +3094%

UUID v3 (name-based and MD5) generation if supported
1. resty-jit-uuid   took:   1.306127s

UUID v5 (name-based and SHA-1) generation if supported
1. resty-jit-uuid   took:   4.834929s

UUID validation if supported (set of 70% valid, 30% invalid)
1. resty-jit-uuid (JIT PCRE enabled)    took:   0.223060s
2. FFI binding                          took:   0.256580s
3. resty-jit-uuid (Lua patterns)        took:   0.444174s
```

* FFI binding: <https://github.com/bungle/lua-resty-uuid>
* C binding: <https://github.com/Mashape/lua-uuid>
* Pure Lua: <https://github.com/Tieske/uuid>
* resty-jit-uuid: this module (base reference for generation % comparison)

**Note**: UUID validation performance in ngx_lua (JIT PCRE) can be greatly
improved by enabling
[lua-resty-core](https://github.com/openresty/lua-resty-core).

[Back to TOC](#table-of-contents)

### Contributions

Suggestions improving this module's or the benchmarks' performance
(of any benchmarked library) are particularly appreciated.

[Back to TOC](#table-of-contents)

### License

Work licensed under the MIT License.

[Back to TOC](#table-of-contents)

[luarocks-resty-jit-uuid]: http://luarocks.org/modules/thibaultcha/lua-resty-jit-uuid

[badge-travis-url]: https://travis-ci.org/thibaultcha/lua-resty-jit-uuid
[badge-travis-image]: https://travis-ci.org/thibaultcha/lua-resty-jit-uuid.svg?branch=master

[badge-coveralls-url]: https://coveralls.io/r/thibaultcha/lua-resty-jit-uuid?branch=master
[badge-coveralls-image]: https://coveralls.io/repos/thibaultcha/lua-resty-jit-uuid/badge.svg?branch=master&style=flat

[badge-version-image]: https://img.shields.io/badge/version-0.0.7-blue.svg?style=flat
