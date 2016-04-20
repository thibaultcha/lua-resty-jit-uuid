# vim:set ts=4 sw=4 et fdm=marker:
use Test::Nginx::Socket::Lua;

our $HttpConfig = <<_EOC_;
    lua_package_path 'lib/?.lua;lib/?/init.lua;;';
_EOC_

master_on();

plan tests => repeat_each() * blocks() * 3;

run_tests();

__DATA__

=== TEST 1: is_valid() PCRE
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local uuid = require 'resty.jit-uuid'
            local tests = {
                'cbb297c0-a956-486d-ad1d-f9b42df9465a',
                '5014127b-4189-494d-b36f-9191cb39bf20',
                '6de59524-0091-48fa-9c13-67908ff5e63c',
                '24b0b2cf-4481-4f41-88b3-aac0a941d756',

                '24b0b2cf-4481-4f41-38b3-aac0a941d756', -- invalid variant
                '24b0b2cf-4481-4f41-88b3-aac0a941d75',
                '24b0b2cf44814f4188b3aac0a941d756',
                '24b&b2cf-4481-4f41-88b3-aac0a941d756',
                '24b0b2cf-4481-4f41-88b3_aac0a941d756'
            }

            for i = 1, #tests do
                ngx.say(uuid.is_valid(tests[i]))
            end
        }
    }
--- request
GET /t
--- response_body
true
true
true
true
false
false
false
false
false
--- no_error_log
[error]



=== TEST 2: is_valid() Lua pattern
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            ngx.config.nginx_configure = function() return '' end
            local uuid = require 'resty.jit-uuid'
            local tests = {
                'cbb297c0-a956-486d-ad1d-f9b42df9465a',
                '5014127b-4189-494d-b36f-9191cb39bf20',
                '6de59524-0091-48fa-9c13-67908ff5e63c',
                '24b0b2cf-4481-4f41-88b3-aac0a941d756',

                '24b0b2cf-4481-4f41-38b3-aac0a941d756', -- invalid variant
                '24b0b2cf-4481-4f41-88b3-aac0a941d75',
                '24b0b2cf44814f4188b3aac0a941d756',
                '24b&b2cf-4481-4f41-88b3-aac0a941d756',
                '24b0b2cf-4481-4f41-88b3_aac0a941d756'
            }

            for i = 1, #tests do
                ngx.say(uuid.is_valid(tests[i]))
            end
        }
    }
--- request
GET /t
--- response_body
true
true
true
true
false
false
false
false
false
--- no_error_log
[error]

