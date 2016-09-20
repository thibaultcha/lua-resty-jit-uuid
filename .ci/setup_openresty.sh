set -e

OPENRESTY_DOWNLOAD=$DOWNLOAD_CACHE/openresty-$OPENRESTY

mkdir -p $OPENRESTY_DOWNLOAD

if [ ! "$(ls -A $OPENRESTY_DOWNLOAD)" ]; then
  OPENRESTY_BASE=openresty-$OPENRESTY
  pushd $DOWNLOAD_CACHE
    curl -L https://openresty.org/download/openresty-$OPENRESTY.tar.gz | tar xz
  popd
fi

OPENRESTY_INSTALL=$INSTALL_CACHE/openresty-$OPENRESTY

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

export PATH="$PATH:$OPENRESTY_INSTALL/nginx/sbin"

git clone git://github.com/travis-perl/helpers travis-perl-helpers
pushd travis-perl-helpers
  source ./init
popd
cpan-install Test::Nginx::Socket
