#!/usr/bin/env bash
# Cross-compile GMP for Android arm64 with the NDK's clang. Step 1 of 3 (GMP -> Nettle -> GnuTLS).
# Run from a build dir under a unix shell (MSYS2 on Windows). See README.md in this folder.
set -e
: "${NDK:?export NDK=/path/to/Android/Sdk/ndk/26.3.11579264}"
WORK="${WORK:-$PWD}"
HOST="${NDK_HOST:-windows-x86_64}"            # NDK prebuilt host dir (linux-x86_64 / darwin-x86_64 / windows-x86_64)
TC="$NDK/toolchains/llvm/prebuilt/$HOST/bin"
API="${API:-24}"
export PATH="$TC:$PATH"
export STAGING="$WORK/sysroot"
export CC="clang --target=aarch64-linux-android$API"
export AR=llvm-ar RANLIB=llvm-ranlib STRIP=llvm-strip NM=llvm-nm
export CFLAGS="-fPIC -O2"
# The Windows NDK clang needs a Windows-style temp dir; on MSYS2 set WINTMP (e.g. C:/build/tmp).
if [ -n "$WINTMP" ]; then mkdir -p "$WINTMP"; export TMPDIR="$WINTMP" TMP="$WINTMP" TEMP="$WINTMP"; fi

cd "$WORK"
rm -rf gmp-6.3.0
tar xf gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --host=aarch64-linux-android --prefix="$STAGING" \
  --disable-shared --enable-static --disable-assembly \
  CC="$CC" AR="$AR" RANLIB="$RANLIB" NM="$NM"
make -j4
make install
