package t::Util;

use strict;
use warnings;

our $HttpConfig = <<'_EOC_';
    lua_package_path 'lib/?.lua;lib/?/init.lua;;';

    init_by_lua_block {
      runner = require 'luacov.runner'
      runner.tick = true
      runner.init {savestepsize = 3}
      jit.off()
    }
_EOC_

1;
