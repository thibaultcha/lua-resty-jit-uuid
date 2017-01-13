package t::Util;

use strict;
use warnings;

my $TEST_COVERAGE_ENABLED = $ENV{TEST_COVERAGE_ENABLED};

my $LuaCovRunner = '';

if ($TEST_COVERAGE_ENABLED) {
$LuaCovRunner = <<_EOC_;
    runner = require 'luacov.runner'
    runner.tick = true
    runner.init {savestepsize = 3}
    jit.off()
_EOC_
}

our $HttpConfig = <<_EOC_;
    lua_package_path './lib/?.lua;./lib/?/init.lua;;';

    init_by_lua_block {
      $LuaCovRunner
    }
_EOC_

our $HttpConfigJit = <<_EOC_;
    lua_package_path './lib/?.lua;./lib/?/init.lua;;';

    init_by_lua_block {
        local verbose = false

        if verbose then
            local dump = require "jit.dump"
            dump.on(nil, "$Test::Nginx::Util::ErrLogFile")

        else
            local v = require "jit.v"
            v.on("$Test::Nginx::Util::ErrLogFile")
        end

        require "resty.core"
    }
_EOC_

1;
