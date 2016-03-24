# vim:set ts=4 sw=4 et fdm=marker:
use Test::Nginx::Socket::Lua;

my $pwd = `pwd`;
chomp $pwd;
our $LuaPackagePath = "$pwd/lib/?.lua;;";

master_on();
workers(2);

plan tests => repeat_each() * blocks() * 3;

run_tests();

__DATA__

=== TEST 1: _VERSION field
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
}
--- config
    location /t {
        content_by_lua_block {
            local uuid = require "resty.jit-uuid"
            ngx.say(uuid._VERSION)
        }
    }
--- request
GET /t
--- response_body_like
[0-9]\.[0-9]\.[0-9]
--- no_error_log
[error]



=== TEST 2: generate uuid
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
}
--- config
    location /t {
        content_by_lua_block {
            local uuid = require "resty.jit-uuid"

            local u = uuid.generate()
            ngx.say(u)
        }
    }
--- request
GET /t
--- response_body_like
[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
--- no_error_log
[error]



=== TEST 3: identical seed for each worker by default
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
    lua_shared_dict uuids 1m;
    init_worker_by_lua_block {
        local uuid = require "resty.jit-uuid"
        local dict = ngx.shared.uuids

        local u = uuid.generate()
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

--- error_log
exists



=== TEST 4: random seeding for each worker
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
    lua_shared_dict uuids 1m;
    init_worker_by_lua_block {
        local uuid = require "resty.jit-uuid"
        local dict = ngx.shared.uuids
        uuid.seed()

        local u = uuid.generate()
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



=== TEST 5: __call metamethod
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
}
--- config
    location /t {
        content_by_lua_block {
            local uuid = require "resty.jit-uuid"
            ngx.say(uuid())
        }
    }
--- request
GET /t
--- response_body_like
[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}
--- no_error_log
[error]



=== TEST 6: is_valid() PCRE
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
}
--- config
    location /t {
        content_by_lua_block {
            local uuid = require "resty.jit-uuid"
            local tests = {
                "cbb297c0-a956-486d-ad1d-f9b42df9465a",
                "5014127b-4189-494d-b36f-9191cb39bf20",
                "6de59524-0091-48fa-9c13-67908ff5e63c",
                "24b0b2cf-4481-4f41-88b3-aac0a941d756",

                "24b0b2cf-4481-5f41-88b3-aac0a941d756", -- invalid version
                "24b0b2cf-4481-4f41-38b3-aac0a941d756", -- invalid variant
                "24b0b2cf-4481-4f41-88b3-aac0a941d75",
                "24b0b2cf44814f4188b3aac0a941d756",
                "24b&b2cf-4481-4f41-88b3-aac0a941d756",
                "24b0b2cf-4481-4f41-88b3_aac0a941d756"
            }

            for _, u in ipairs(tests) do
                ngx.say(uuid.is_valid(u))
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
false
--- no_error_log
[error]



=== TEST 7: is_valid() Lua pattern
--- http_config eval
qq{
    lua_package_path '$::LuaPackagePath';
}
--- config
    location /t {
        content_by_lua_block {
            ngx.config.nginx_configure = function() return "" end
            local uuid = require "resty.jit-uuid"
            local tests = {
                "cbb297c0-a956-486d-ad1d-f9b42df9465a",
                "5014127b-4189-494d-b36f-9191cb39bf20",
                "6de59524-0091-48fa-9c13-67908ff5e63c",
                "24b0b2cf-4481-4f41-88b3-aac0a941d756",

                "24b0b2cf-4481-5f41-88b3-aac0a941d756", -- invalid version
                "24b0b2cf-4481-4f41-38b3-aac0a941d756", -- invalid variant
                "24b0b2cf-4481-4f41-88b3-aac0a941d75",
                "24b0b2cf44814f4188b3aac0a941d756",
                "24b&b2cf-4481-4f41-88b3-aac0a941d756",
                "24b0b2cf-4481-4f41-88b3_aac0a941d756"
            }

            for _, u in ipairs(tests) do
                ngx.say(uuid.is_valid(u))
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
false
--- no_error_log
[error]

