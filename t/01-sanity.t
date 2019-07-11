# vim:sts=4 ts=4 sw=4 et fdm=marker:
use lib '.';
use Test::Nginx::Socket::Lua;
use t::Util;

our $HttpConfig = $t::Util::HttpConfig;

master_on();
workers(2);

plan tests => repeat_each() * blocks() * 3 - 1;

run_tests();

__DATA__

=== TEST 1: _VERSION field
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'
            ngx.say(uuid._VERSION)
        }
    }
--- request
GET /t
--- response_body_like
[0-9]\.[0-9]\.[0-9]
--- no_error_log
[error]



=== TEST 2: seed() identical seed for each worker by default
--- http_config eval
qq{
    $::HttpConfig
    lua_shared_dict randoms 1m;
    init_worker_by_lua_block {
        local uuid = require 'resty.jit-uuid'
        local dict = ngx.shared.randoms

        local u = math.random()
        assert(dict:add(u, true))
    }
}
--- config
    location /t {
        return 200;
    }
--- request
GET /t
--- response_body

--- error_log
exists



=== TEST 3: seed() random seeding for each worker
--- http_config eval
qq{
    $::HttpConfig
    lua_shared_dict randoms 1m;
    init_worker_by_lua_block {
        local uuid = require 'resty.jit-uuid'
        local dict = ngx.shared.randoms
        uuid.seed()

        local u = math.random()
        assert(dict:add(u, true))
    }
}
--- config
    location /t {
        return 200;
    }
--- request
GET /t
--- response_body_like

--- no_error_log
[error]



=== TEST 4: seed() uses custom seed and returns used value
--- http_config eval
qq{
    $::HttpConfig
}
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'
            local seed = uuid.seed(1234)
            ngx.say(seed)
        }
    }
--- request
GET /t
--- response_body
1234
--- no_error_log



=== TEST 5: __call metamethod
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'
            ngx.say(uuid())
        }
    }
--- request
GET /t
--- response_body_like
[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
--- no_error_log
[error]
