#!/usr/bin/env bash
set -e
NDK=/c/Users/Leland/AppData/Local/Android/Sdk/ndk/26.3.11579264
TC=$NDK/toolchains/llvm/prebuilt/windows-x86_64/bin
export PATH="$TC:/usr/bin:/bin:$PATH"
export STAGING=/c/Users/Leland/android-dev/tls-build/sysroot
API=24
export CC="clang --target=aarch64-linux-android$API"
export AR=llvm-ar RANLIB=llvm-ranlib STRIP=llvm-strip NM=llvm-nm
export CFLAGS="-fPIC -O2" CXXFLAGS="-fPIC -O2"
export CPPFLAGS="-I$STAGING/include"
# 16 KB page alignment: Android 15+ / 16 KB-page devices reject .so with 4 KB-aligned LOAD
# segments (libftedroid.so already builds with this; libgnutls.so must match).
export LDFLAGS="-L$STAGING/lib -Wl,-z,max-page-size=16384,-z,common-page-size=16384"
export PKG_CONFIG_PATH="$STAGING/lib/pkgconfig"
export PKG_CONFIG_LIBDIR="$STAGING/lib/pkgconfig"
export GMP_CFLAGS="-I$STAGING/include" GMP_LIBS="-L$STAGING/lib -lgmp"
mkdir -p /c/Users/Leland/android-dev/tls-build/tmp
export TMPDIR="C:/Users/Leland/android-dev/tls-build/tmp"; export TMP="$TMPDIR" TEMP="$TMPDIR"

cd /c/Users/Leland/android-dev/tls-build
rm -rf gnutls-3.8.5
tar xf gnutls-3.8.5.tar.xz
cd gnutls-3.8.5

echo "===== configure gnutls ====="
./configure --host=aarch64-linux-android --prefix="$STAGING" \
  --enable-shared --disable-static \
  --with-included-libtasn1 --with-included-unistring \
  --without-p11-kit --without-idn --without-tpm --without-tpm2 \
  --without-zlib --without-brotli --without-zstd \
  --disable-doc --disable-tests --disable-tools --disable-cxx \
  --disable-nls --disable-libdane --disable-guile --disable-rpath \
  --disable-hardware-acceleration \
  CC="$CC" AR="$AR" RANLIB="$RANLIB" NM="$NM" \
  2>&1 | tail -30

echo "===== make gnutls ====="
make -j4 2>&1 | tail -8
make install 2>&1 | tail -4
echo "===== result ====="
ls -la "$STAGING/lib/"libgnutls.so* 2>&1
echo "--- NEEDED deps (want only android system libs) ---"
llvm-readelf -d "$STAGING/lib/libgnutls.so" 2>/dev/null | grep -i "needed\|soname" || true
echo "--- arch ---"; llvm-readelf -h "$STAGING/lib/libgnutls.so" 2>/dev/null | grep -i machine | head -1
