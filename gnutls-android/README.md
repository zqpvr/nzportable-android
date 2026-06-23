# Building libgnutls.so for Android

These scripts cross-compile GnuTLS (and its GMP + Nettle dependencies) into the single
self-contained `app/src/main/jniLibs/arm64-v8a/libgnutls.so` that the engine loads at runtime
for the encrypted (DTLS) multiplayer connections. The prebuilt `.so` is already committed, so
you only need these if you want to rebuild it.

You need a unix shell with autotools/make and the Android NDK. On Windows, MSYS2 works (these
were built that way). Get the source tarballs:

- GMP 6.3.0    — https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
- Nettle 3.10  — https://ftp.gnu.org/gnu/nettle/nettle-3.10.tar.gz
- GnuTLS 3.8.5 — https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.5.tar.xz

Put the three tarballs in a build directory, then from that directory:

```sh
export NDK=/path/to/Android/Sdk/ndk/26.3.11579264
# On Windows/MSYS2 the NDK clang needs a Windows-style temp dir and host name:
export WINTMP=C:/build/tmp ; export NDK_HOST=windows-x86_64

/path/to/gnutls-android/build-gmp.sh
/path/to/gnutls-android/build-nettle.sh
/path/to/gnutls-android/build-gnutls.sh
```

The result is `sysroot/lib/libgnutls.so`. Copy it to `app/src/main/jniLibs/arm64-v8a/libgnutls.so`
and strip it (`llvm-strip --strip-all`).
