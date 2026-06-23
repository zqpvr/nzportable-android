#!/usr/bin/env bash
# Cross-compile GnuTLS (static-linking the GMP+Nettle from steps 1-2) for Android arm64. Step 3 of 3.
# Produces a self-contained libgnutls.so (NEEDED = libc/libdl only), 16 KB-page aligned.
# Run from the same build dir after build-gmp.sh and build-nettle.sh. See README.md in this folder.
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
export CFLAGS="-fPIC -O2" CXXFLAGS="-fPIC -O2"
export CPPFLAGS="-I$STAGING/include"
# 16 KB page alignment: Android 15+ / 16 KB-page devices reject .so with 4 KB-aligned LOAD segments
# (libftedroid.so builds with this; libgnutls.so must match or dlopen fails on those devices).
export LDFLAGS="-L$STAGING/lib -Wl,-z,max-page-size=16384,-z,common-page-size=16384"
export PKG_CONFIG_PATH="$STAGING/lib/pkgconfig" PKG_CONFIG_LIBDIR="$STAGING/lib/pkgconfig"
export GMP_CFLAGS="-I$STAGING/include" GMP_LIBS="-L$STAGING/lib -lgmp"
if [ -n "$WINTMP" ]; then mkdir -p "$WINTMP"; export TMPDIR="$WINTMP" TMP="$WINTMP" TEMP="$WINTMP"; fi

cd "$WORK"
rm -rf gnutls-3.8.5
tar xf gnutls-3.8.5.tar.xz
cd gnutls-3.8.5
./configure --host=aarch64-linux-android --prefix="$STAGING" \
  --enable-shared --disable-static \
  --with-included-libtasn1 --with-included-unistring \
  --without-p11-kit --without-idn --without-tpm --without-tpm2 \
  --without-zlib --without-brotli --without-zstd \
  --disable-doc --disable-tests --disable-tools --disable-cxx \
  --disable-nls --disable-libdane --disable-guile --disable-rpath \
  --disable-hardware-acceleration \
  CC="$CC" AR="$AR" RANLIB="$RANLIB" NM="$NM"
make -j4
make install
# Final lib is $STAGING/lib/libgnutls.so -- copy to app/src/main/jniLibs/arm64-v8a/libgnutls.so
# (rename off the version suffix) and strip it: llvm-strip --strip-all libgnutls.so
