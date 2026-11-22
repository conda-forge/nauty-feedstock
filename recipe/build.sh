#!/bin/bash
set -ex

if [[ "$target_platform" == win-* ]]; then
    export CC=clang-cl
    export CFLAGS="-MD -O2"
    export CPPFLAGS=
    export LDFLAGS=
fi

autoreconf -vfi

# --disable-shared: we only build static because nauty originally didn't
# support dynamic libraries; enabling it would require us to run_exports more
# strictly because the soname changes with each release. Also the Windows setup
# cannot build a shared library because the headers have no dllimport setup.
./configure --prefix="$PREFIX" \
            --includedir='${prefix}/include/nauty' \
            --disable-shared \
            --disable-popcnt --disable-clz --enable-generic --enable-tls
make

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
    make checks
fi

make install

# The libraries are static and have no dependencies; nothing should link
# through libtool archives from the package.
rm -f "$PREFIX"/lib/*.la

if [[ "$target_platform" == win-* ]]; then
    # The .pc files record the build prefix in MSYS form (/c/...), which conda
    # does not relocate; make them relative to their own location instead.
    sed -i 's|^prefix=.*|prefix=${pcfiledir}/../..|' "$PREFIX"/lib/pkgconfig/*.pc
fi
