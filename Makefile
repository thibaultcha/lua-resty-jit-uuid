.PHONY: test lint bench doc coverage

test:
	@t/reindex t/*.t
	@prove

lint:
	@luacheck -q lib --std 'luajit+ngx_lua' \
	  --no-redefined

bench:
	@luarocks install uuid
	@luarocks install lua-resty-uuid
	@luarocks install lua_uuid
	@resty bench.lua

doc:
	@luarocks install ldoc
	@ldoc -c docs/config.ld lib

coverage: test
	@luacov -i lib/resty
