#!/usr/bin/env bash
set -e
NDK=/c/Users/Leland/AppData/Local/Android/Sdk/ndk/26.3.11579264
TC=$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin
export PATH="$TC:/usr/bin:/bin:$PATH"
export STAGING=/c/Users/Leland/android-dev/tls-build/sysroot
API=24
export CC="clang --target=aarch64-linux-android$API"
export AR=llvm-ar RANLIB=llvm-ranlib STRIP=llvm-strip NM=llvm-nm
export CFLAGS="-fPIC -O2"
mkdir -p /c/Users/Leland/android-dev/tls-build/tmp
export TMPDIR="C:/Users/Leland/android-dev/tls-build/tmp"; export TMP="$TMPDIR" TEMP="$TMPDIR"

cd /c/Users/Leland/android-dev/tls-build
rm -rf nettle-3.10
tar xf nettle-3.10.tar.gz
cd nettle-3.10

echo "===== configure nettle (real GMP) ====="
./configure --host=aarch64-linux-android --prefix="$STAGING" \
  --disable-shared --enable-static --disable-documentation --disable-openssl \
  CC="$CC" AR="$AR" RANLIB="$RANLIB" \
  CPPFLAGS="-I$STAGING/include" LDFLAGS="-L$STAGING/lib" 2>&1 | grep -iE "mini-gmp|public key|GMP|error" | head

echo "===== make nettle ====="
make -j4 2>&1 | tail -4
make install 2>&1 | tail -3
echo "===== done; libs ====="; ls -la "$STAGING/lib/"libnettle.a "$STAGING/lib/"libhogweed.a
