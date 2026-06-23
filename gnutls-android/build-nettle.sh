#!/usr/bin/env bash
# Cross-compile Nettle (against the GMP from step 1) for Android arm64. Step 2 of 3.
# Run from the same build dir after build-gmp.sh. See README.md in this folder.
set -e
: "${NDK:?export NDK=/path/to/Android/Sdk/ndk/26.3.11579264}"
WORK="${WORK:-$PWD}"
HOST="${NDK_HOST:-windows-x86_64}"
TC="$NDK/toolchains/llvm/prebuilt/$HOST/bin"
API="${API:-24}"
export PATH="$TC:$PATH"
export STAGING="$WORK/sysroot"
export CC="clang --target=aarch64-linux-android$API"
export AR=llvm-ar RANLIB=llvm-ranlib STRIP=llvm-strip NM=llvm-nm
export CFLAGS="-fPIC -O2"
if [ -n "$WINTMP" ]; then mkdir -p "$WINTMP"; export TMPDIR="$WINTMP" TMP="$WINTMP" TEMP="$WINTMP"; fi

cd "$WORK"
rm -rf nettle-3.10
tar xf nettle-3.10.tar.gz
cd nettle-3.10
./configure --host=aarch64-linux-android --prefix="$STAGING" \
  --disable-shared --enable-static --disable-documentation --disable-openssl \
  CC="$CC" AR="$AR" RANLIB="$RANLIB" \
  CPPFLAGS="-I$STAGING/include" LDFLAGS="-L$STAGING/lib"
make -j4
make install
