# Patches

Source changes this port needs, kept as patches so the upstream repos stay
pristine (and updatable). Game data (`app/src/main/assets/nzp/`) is gitignored
and produced at build time.

## 0001-fteqw-android-build.patch
Applies to the **`fteqw`** submodule (nzp-team/fteqw — the engine).
```
cd fteqw && git apply ../patches/0001-fteqw-android-build.patch
```
Covers the Android bring-up: build fixes, GLES/Vulkan rotation, audio thread,
controller input (reflection fixes, devid tagging, D-pad hat, stick nav),
in-APK data extraction, immersive fullscreen, and the embedded NZ:P manifest
(`mainconfig nzportable.cfg`, `in_forceseat`, aim-assist default).

## 0002-nzp-quakec.patch
Applies to the **NZ:P QuakeC** game code (nzp-team/quakec), which is built
separately into `csprogs.dat`.
```
git clone https://github.com/nzp-team/quakec
cd quakec && git apply ../patches/0002-nzp-quakec.patch
# build (Windows): tools\qc-compiler-win.bat  (csprogs.dat + menu.dat build
# without the python/pandas hash step; only the server progs need it)
cd bin && ./fteqcc-cli-win.exe -DFTE -Wall -srcfile ../progs/csqc.src
# then copy build/fte/csprogs.dat into app/src/main/assets/nzp/
```
Two changes: (1) sets `gamepad_enabled` when controller input arrives — NZ:P
never sets it, so aim assist (gated on that flag) was dead even on desktop;
(2) adds a RENDERER toggle (Vulkan/OpenGL) to the video-options menu. Rebuild
both `csprogs.dat` (from csqc.src) and `menu.dat` (from menu.src).

## Game-data prep (`app/src/main/assets/nzp/`, gitignored, bundled at build)
Start from the official `nzp` data (any NZ:P desktop/nightly release), then:
- replace `csprogs.dat` with the one built from patch 0002 (aim assist).
- in `nzportable.cfg`, set `vid_renderer ""` — empty makes the engine auto-pick
  the highest-priority renderer, which on Android is **Vulkan** (the rotation is
  handled by the swapchain pre-transform fix in patch 0001). `"gl"` forces GLES.

### Config layering gotcha
NZ:P's boot order is `default.cfg` -> `nzportable.cfg` (the mainconfig, which
`exec`s `user_settings.cfg` at its end) -> manifest `defaultoverrides`. The
engine *saves* to `user_settings.cfg` (full dump of all cvars/binds), and because
that file is exec'd last it **overrides both nzportable.cfg and our manifest
binds/cvars**. So a stale `user_settings.cfg` will silently pin `vid_renderer`
and the controller layout. Delete it to fall back to defaults.

## Online multiplayer (GnuTLS for the broker's TLS/DTLS)
NZ:P 2.0's online play uses FTE's ICE broker (`tls://master.frag-net.com`), which
**requires DTLS** (`net_ice.c`: "dtls+sctp is a mandatory part of our connection").
FTE's only crypto backend is GnuTLS, `dlopen`'d at runtime - absent on Android. So
we cross-compile GnuTLS for arm64 and bundle it:

- `gnutls-android/build-{gmp,nettle,gnutls}.sh` build the chain with the NDK clang
  under MSYS2: GMP (`--disable-assembly`) -> Nettle (real GMP) -> GnuTLS (minimal:
  included libtasn1/unistring, no p11-kit/idn/doc/tools), with GMP+Nettle
  **static-linked** into one self-contained `libgnutls.so` (NEEDED = libc/libdl
  only). Built with `-Wl,-z,max-page-size=16384` so its LOAD segments are 16 KB
  aligned (16 KB-page devices reject 4 KB-aligned libs - that was the `dlopen` fail).
- Vendored: `app/src/main/jniLibs/arm64-v8a/libgnutls.so` + `app/gnutls-include/`.
- Build wiring (patch 0001 + build.gradle): `net_ssl_gnutls.c` added to the
  `ftedroid` target; `-DFTE_DEP_GNUTLS=false` so CMake's failing `FIND_PACKAGE(GnuTLS)`
  doesn't define `NO_GNUTLS`; `-I app/gnutls-include` for the headers.
- Runtime (patch 0001): `System.loadLibrary("gnutls")` in `FTENativeActivity`, plus
  a fallback in `net_ssl_gnutls.c` from the versioned soname (`libgnutls.so.30`,
  which an APK can't carry) to the bare `libgnutls.so`.

Verified: the engine loads GnuTLS, generates a DTLS cert, and registers with
master.frag-net.com. (DTLS interop with the Windows host's SChannel backend is the
remaining piece.)

### LAN discovery
`masters.txt` (game data) adds a `bcast` master so the Co-op > Browse refresh
broadcasts a QW/FTE query across the local network, listing LAN listen-servers.

