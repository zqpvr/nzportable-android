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
rm -rf gmp-6.3.0
tar xf gmp-6.3.0.tar.xz
cd gmp-6.3.0

echo "===== configure gmp ====="
./configure --host=aarch64-linux-android --prefix="$STAGING" \
  --disable-shared --enable-static --disable-assembly \
  CC="$CC" AR="$AR" RANLIB="$RANLIB" NM="$NM" 2>&1 | tail -20

echo "===== make gmp ====="
make -j4 2>&1 | tail -8
make install 2>&1 | tail -5
echo "===== result ====="
ls -la "$STAGING/lib/libgmp.a" 2>&1
llvm-readelf -h "$STAGING/lib/libgmp.a" 2>/dev/null | grep -i machine | head -1
