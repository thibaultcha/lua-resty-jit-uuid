# vim:set ts=4 sw=4 et fdm=marker:
use Test::Nginx::Socket::Lua;

our $HttpConfig = <<_EOC_;
    lua_package_path 'lib/?.lua;lib/?/init.lua;;';
_EOC_

master_on();

plan tests => repeat_each() * blocks() * 3 - 2;

run_tests();

__DATA__

=== TEST 1: generate_v3() generates v3 compliant UUIDs
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'

            ngx.say(uuid.generate_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d', 'hello'))
            ngx.say(uuid.generate_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d', 'foobar'))

            ngx.say(uuid.generate_v3('1b985f4a-06be-11e6-aff4-ff8d14e25128', 'hello'))
            ngx.say(uuid.generate_v3('1b985f4a-06be-11e6-aff4-ff8d14e25128', 'foobar'))
        }
    }
--- request
GET /t
--- response_body
3db7a435-8c56-359d-a563-1b69e6802c78
e8d3eeba-7723-3b72-bbc5-8f598afa6773
5dcd9919-b318-3ef8-bfb1-c81f44c72084
4b95b7c2-b914-3c46-9899-e0138a185670
--- no_error_log
[error]



=== TEST 2: factory_v3() gives a UUID factory
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'

            local fact, err = uuid.factory_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d')
            if not fact then
                ngx.log(ngx.ERR, err)
                return
            end

            ngx.say(fact('hello'))
            ngx.say(fact('foobar'))
        }
    }
--- request
GET /t
--- response_body
3db7a435-8c56-359d-a563-1b69e6802c78
e8d3eeba-7723-3b72-bbc5-8f598afa6773
--- no_error_log
[error]



=== TEST 3: generate_v3() no PCRE
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.config.nginx_configure = function() return '' end
            local uuid = require 'resty.jit-uuid'

            local fact, err = uuid.factory_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d')
            if not fact then
                ngx.log(ngx.ERR, err)
                return
            end

            ngx.say(fact('hello'))
            ngx.say(fact('foobar'))
        }
    }
--- request
GET /t
--- response_body
3db7a435-8c56-359d-a563-1b69e6802c78
e8d3eeba-7723-3b72-bbc5-8f598afa6773
--- no_error_log
[error]



=== TEST 4: factory_v3() no support outside of ngx_lua
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx = false
            local uuid = require 'resty.jit-uuid'

            uuid.factory_v3()
        }
    }
--- request
GET /t
--- error_code: 500
--- error_log
v3 UUID generation only supported in ngx_lua



=== TEST 5: generate_v3() no support outside of ngx_lua
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx = false
            local uuid = require 'resty.jit-uuid'

            uuid.generate_v3()
        }
    }
--- request
GET /t
--- error_code: 500
--- error_log
v3 UUID generation only supported in ngx_lua



=== TEST 6: invalid namespace
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'

            local u, err = uuid.generate_v3('foobar', 'hello')
            if not u then
                ngx.say(err)
            end
        }
    }
--- request
GET /t
--- response_body
namespace must be a valid UUID
--- no_error_log
[error]



=== TEST 7: invalid name
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'

            local u, err = uuid.generate_v3('e6ebd542-06ae-11e6-8e82-bba81706b27d', false)
            if not u then
                ngx.say(err)
            end
        }
    }
--- request
GET /t
--- response_body
name must be a string
--- no_error_log
[error]

