set -e

OPENRESTY_DOWNLOAD=$DOWNLOAD_CACHE/openresty-$OPENRESTY
LUAROCKS_DOWNLOAD=$DOWNLOAD_CACHE/luarocks-$LUAROCKS

mkdir -p $OPENRESTY_DOWNLOAD

if [ ! "$(ls -A $OPENRESTY_DOWNLOAD)" ]; then
  OPENRESTY_BASE=openresty-$OPENRESTY
  pushd $DOWNLOAD_CACHE
    curl -L https://openresty.org/download/openresty-$OPENRESTY.tar.gz | tar xz
  popd
fi

if [ ! "$(ls -A $LUAROCKS_DOWNLOAD)" ]; then
  git clone https://github.com/keplerproject/luarocks.git $LUAROCKS_DOWNLOAD
fi


OPENRESTY_INSTALL=$INSTALL_CACHE/openresty-$OPENRESTY
LUAROCKS_INSTALL=$INSTALL_CACHE/luarocks-$LUAROCKS

mkdir -p $OPENRESTY_INSTALL

if [ ! "$(ls -A $OPENRESTY_INSTALL)" ]; then
  pushd $OPENRESTY_DOWNLOAD
    ./configure \
      --prefix=$OPENRESTY_INSTALL \
      --with-pcre-jit
    make
    make install
  popd
fi

if [ ! "$(ls -A $LUAROCKS_INSTALL)" ]; then
  pushd $LUAROCKS_DOWNLOAD
    git checkout v$LUAROCKS
    ./configure \
      --prefix=$LUAROCKS_INSTALL \
      --lua-suffix=jit \
      --with-lua=$OPENRESTY_INSTALL/luajit \
      --with-lua-include=$OPENRESTY_INSTALL/luajit/include/luajit-2.1
    make build
    make install
  popd
fi

export PATH="$PATH:$OPENRESTY_INSTALL/nginx/sbin:$LUAROCKS_INSTALL/bin"

eval `luarocks path`

git clone git://github.com/travis-perl/helpers travis-perl-helpers
pushd travis-perl-helpers
  source ./init
popd
cpan-install Test::Nginx::Socket
