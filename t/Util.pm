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
    lua_package_path \'./lib/?.lua;./lib/?/init.lua;;\';

    init_by_lua_block {
      $LuaCovRunner
    }
_EOC_

1;
