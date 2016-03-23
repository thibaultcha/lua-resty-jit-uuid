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

=== TEST 1: generate uuid
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



=== TEST 2: identical seed for each worker by default
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



=== TEST 3: random seeding for each worker
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



=== TEST 4: __call metamethod
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

