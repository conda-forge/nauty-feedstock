#!/bin/bash

export CFLAGS="-O2 -g $CFLAGS"

if [[ "$target_platform" == "win-64" ]]; then
    export PATH="$PREFIX/Library/bin:$BUILD_PREFIX/Library/bin:$PATH"
    export CC=clang-cl
    export RANLIB=llvm-ranlib
    export AS=llvm-as
    export AR=llvm-ar
    export LD=lld-link
    export CFLAGS="-MD -I$PREFIX/Library/include -O2"
    export LDFLAGS="$LDFLAGS -L$PREFIX/Library/lib"
    export LIBRARY_PREFIX=$PREFIX/Library
else
    export CFLAGS="$CFLAGS -fPIC"
    export LIBRARY_PREFIX=$PREFIX
    # Get an updated config.sub and config.guess
    cp $BUILD_PREFIX/share/gnuconfig/config.guess config.guess
    cp $BUILD_PREFIX/share/gnuconfig/config.sub config.sub
fi

sed -i.bak 's/popsup=0/popsup=0,popsup=0/g' configure.ac
rm aclocal.m4
autoreconf -vfi
./configure --disable-popcnt --disable-clz --enable-generic --enable-tls
make

programs="addedgeg addptg amtog ancestorg assembleg biplabg catg complg converseg copyg \
  countg countneg cubhamg deledgeg delptg dimacs2g directg dreadnaut dretodot \
  dretog edgetransg genbg genbgL geng gengL genposetg genquarticg genrang \
  genspecialg gentourng gentreeg genktreeg hamheuristic labelg linegraphg listg \
  multig nbrhoodg newedgeg pickg planarg productg ranlabg ransubg shortg showg \
  subdivideg twohamg underlyingg vcolg watercluster2 NRswitchg"

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
    make checks || true
    check_output=`make checks || true`
    echo "$check_output"
    if [[ "$target_platform" == "win-64" ]]; then
        # countg and pickg are not supported on platforms with size(void*) != size(long)
        if [[ "$check_output" != *"3 TESTS FAILED"* ]]; then
          exit 1
        fi
    else
        if [[ "$check_output" != *"PASSED ALL TESTS"* ]]; then
          exit 1
        fi
    fi
fi

if [[ "$target_platform" != win-* ]]; then
    programs="$programs countg pickg shortg"
fi

mkdir -p "$LIBRARY_PREFIX"/bin
for program in $programs;
do
  cp -p $program "$LIBRARY_PREFIX"/bin/$program
done

mkdir -p "$LIBRARY_PREFIX"/lib
libs="nauty nauty1 nautyL nautyL1 nautyW nautyW1"
for lib in $libs;
do
  if [[ "$target_platform" == "win-64" ]]; then
    cp -p $lib.a "$LIBRARY_PREFIX"/lib/$lib.lib
  else
    cp -p $lib.a "$LIBRARY_PREFIX"/lib/lib$lib.a
  fi
done

mkdir -p "$LIBRARY_PREFIX"/include/nauty
cp *.h "$LIBRARY_PREFIX"/include/nauty/
