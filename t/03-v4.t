# vim:set sts=4 ts=4 sw=4 et fdm=marker:
use Test::Nginx::Socket::Lua;
use t::Util;

our $HttpConfig = $t::Util::HttpConfig;

master_on();

plan tests => repeat_each() * blocks() * 3 + 2;

run_tests();

__DATA__

=== TEST 1: generate_v4() generates v4 compliant UUIDs
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'

            uuid.seed()

            ngx.say(uuid.generate_v4())
        }
    }
--- request
GET /t
--- response_body_like
^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$
--- no_error_log
[error]



=== TEST 2: generate_v4() JIT compiles
--- http_config eval: $t::Util::HttpConfigJit
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'

            for _ = 1, 100 do
                uuid()
            end
        }
    }
--- request
GET /t
--- response_body

--- error_log eval
qr/\[TRACE   \d+ content_by_lua\(nginx\.conf:\d+\):4 loop\]/
--- no_error_log
[error]
-- NYI:
