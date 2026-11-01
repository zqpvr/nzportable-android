#!/usr/bin/env bash
# Builds app/src/main/jniLibs/arm64-v8a/libgnutls.so and the headers in app/gnutls-include/,
# which the engine needs for the DTLS that online play goes through. GMP and Nettle are linked
# in statically, so the library depends on nothing but libc and libdl.
#
# Needs the NDK (ANDROID_NDK_HOME, or the ndkVersion from app/build.gradle under ANDROID_HOME),
# make, m4 and curl.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GMP=gmp-6.3.0;          GMP_SHA256=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
NETTLE=nettle-3.10.2;   NETTLE_SHA256=fe9ff51cb1f2abb5e65a6b8c10a92da0ab5ab6eaf26e7fc2b675c45f1fb519b5
GNUTLS=gnutls-3.8.13;   GNUTLS_SHA256=ffed8ec1bf09c2426d4f14aae377de4753b53e537d685e604e99a8b16ca9c97e

NDK="${ANDROID_NDK_HOME:-${ANDROID_HOME:?set ANDROID_HOME or ANDROID_NDK_HOME}/ndk/$(sed -n "s/.*ndkVersion = '\(.*\)'/\1/p" "$ROOT/app/build.gradle")}"
TC="$NDK/toolchains/llvm/prebuilt/$(uname -s | tr A-Z a-z)-x86_64/bin"
export PATH="$TC:$PATH"
export CC="clang --target=aarch64-linux-android24" AR=llvm-ar RANLIB=llvm-ranlib NM=llvm-nm
export CFLAGS="-fPIC -O2"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
staging="$work/sysroot"
cd "$work"

fetch() {	# url sha256
    curl -fsSL --retry 3 -o "${1##*/}" "$1"
    echo "$2  ${1##*/}" | sha256sum -c --quiet
    tar xf "${1##*/}"
}
fetch "https://ftp.gnu.org/gnu/gmp/$GMP.tar.xz" $GMP_SHA256
fetch "https://ftp.gnu.org/gnu/nettle/$NETTLE.tar.gz" $NETTLE_SHA256
fetch "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/$GNUTLS.tar.xz" $GNUTLS_SHA256

(cd $GMP && ./configure -q --host=aarch64-linux-android --prefix="$staging" \
    --disable-shared --enable-static --disable-assembly && make -s -j"$(nproc)" && make -s install)

(cd $NETTLE && ./configure -q --host=aarch64-linux-android --prefix="$staging" \
    --disable-shared --enable-static --disable-documentation --disable-openssl \
    CPPFLAGS="-I$staging/include" LDFLAGS="-L$staging/lib" && make -s -j"$(nproc)" && make -s install)

(cd $GNUTLS && PKG_CONFIG_PATH="$staging/lib/pkgconfig" PKG_CONFIG_LIBDIR="$staging/lib/pkgconfig" \
    GMP_CFLAGS="-I$staging/include" GMP_LIBS="-L$staging/lib -lgmp" \
    ./configure -q --host=aarch64-linux-android --prefix="$staging" \
    --enable-shared --disable-static \
    --with-included-libtasn1 --with-included-unistring \
    --without-p11-kit --without-idn --without-tpm --without-tpm2 \
    --without-zlib --without-brotli --without-zstd \
    --disable-doc --disable-tests --disable-tools --disable-cxx \
    --disable-nls --disable-libdane --disable-guile --disable-rpath \
    --disable-hardware-acceleration \
    CPPFLAGS="-I$staging/include" LDFLAGS="-L$staging/lib" && make -s -j"$(nproc)" && make -s install)

# the engine dlopens the unversioned name
llvm-strip --strip-all -o "$ROOT/app/src/main/jniLibs/arm64-v8a/libgnutls.so" "$(readlink -f "$staging/lib/libgnutls.so")"
rm -rf "$ROOT/app/gnutls-include/gnutls"
cp -r "$staging/include/gnutls" "$ROOT/app/gnutls-include/"
echo "$GNUTLS with $NETTLE and $GMP: $(du -h "$ROOT/app/src/main/jniLibs/arm64-v8a/libgnutls.so" | cut -f1)"
