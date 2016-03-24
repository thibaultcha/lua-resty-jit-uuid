.PHONY: test lint bench doc

test:
	@t/reindex t/*.t
	@prove

lint:
	@luacheck -q lib --std 'luajit+ngx_lua'

bench:
	@luarocks install uuid
	@luarocks install lua-resty-uuid
	@luarocks install lua_uuid
	@luajit bench.lua

doc:
	@luarocks install ldoc
	@ldoc -c doc/config.ld lib

