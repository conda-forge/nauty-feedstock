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
autoreconf -vfi
./configure --disable-popcnt --disable-clz --enable-generic
make

programs="addedgeg amtog biplabg catg complg converseg copyg cubhamg deledgeg delptg directg dreadnaut dretodot dretog \
  genbg genbgL geng genquarticg genrang genspecialg gentourng gentreeg hamheuristic labelg linegraphg listg multig newedgeg \
  planarg ranlabg showg subdivideg twohamg vcolg watercluster2 NRswitchg"

if [[ "$CONDA_BUILD_CROSS_COMPILATION" != "1" ]]; then
    check_output=`make checks`
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
