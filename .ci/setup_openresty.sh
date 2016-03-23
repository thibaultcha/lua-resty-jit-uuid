set -e

mkdir -p $OPENRESTY_DIR

if [ ! "$(ls -A $OPENRESTY_DIR)" ]; then
  OPENRESTY_BASE=openresty-$OPENRESTY

  curl https://openresty.org/download/$OPENRESTY_BASE.tar.gz | tar xz
  pushd $OPENRESTY_BASE
    ./configure \
      --prefix=$OPENRESTY_DIR \
      --without-http_coolkit_module \
      --without-lua_resty_dns \
      --without-lua_resty_lrucache \
      --without-lua_resty_upstream_healthcheck \
      --without-lua_resty_websocket \
      --without-lua_resty_upload \
      --without-lua_resty_string \
      --without-lua_resty_mysql \
      --without-lua_resty_redis \
      --without-http_redis_module \
      --without-http_redis2_module \
      --without-lua_redis_parser
    make
    make install
  popd
fi

git clone git://github.com/travis-perl/helpers travis-perl-helpers
pushd travis-perl-helpers
  source ./init
popd
cpan-install Test::Nginx::Socket
