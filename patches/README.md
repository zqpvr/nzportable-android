# Patches

The engine used to live here as a patch file. It doesn't any more: the `fteqw`
submodule now points at our own fork (`zqpvr/fteqw`, branch `android`), where
the port's changes are ordinary commits on top of upstream. Engine work is done
by committing to that repo and moving the submodule pointer, not by regenerating
a ten-thousand-line diff.

What remains here is the QuakeC patch, because the game code is built from a
separate upstream repo that isn't a submodule.

## 0002-nzp-quakec.patch
Applies to the **NZ:P QuakeC** game code (nzp-team/quakec), built separately
into `csprogs.dat` and `menu.dat`. `0002-base.txt` records the upstream commit
it was written against; CI falls back to that commit if the patch stops
applying to upstream's tip, rather than shipping stale code.

```
git clone https://github.com/nzp-team/quakec
cd quakec && tr -d '\r' < ../patches/0002-nzp-quakec.patch | git apply --3way --ignore-whitespace -
cd bin && ./fteqcc-cli-win.exe -DFTE -srcfile ../progs/csqc.src
         ./fteqcc-cli-win.exe -DFTE -srcfile ../progs/menu.src
# then copy build/fte/{csprogs,menu}.dat into app/src/main/assets/nzp/
```

It carries the on-screen touch controls, the touch handling for both menu
programs, the advanced video menu, aim assist (which NZ:P never enables,
because `gamepad_enabled` is never set), and the renderer toggle.

## Game data (`app/src/main/assets/nzp/`)
Start from the official `nzp` data (any NZ:P desktop or nightly release), then
overlay the two `.dat` files built above and the touch artwork in `gfx/touch/`.
In `nzportable.cfg`, leave `vid_renderer` empty: the engine then picks the
highest-priority renderer, which on Android is Vulkan. `"gl"` forces GLES.

### Config layering gotcha
The boot order is `default.cfg` -> `nzportable.cfg` (the mainconfig, which
`exec`s `user_settings.cfg` at its end) -> manifest `defaultoverrides`. The
engine *saves* to `user_settings.cfg`, a full dump of every cvar and bind, and
because that file is exec'd last it **overrides both nzportable.cfg and the
manifest**. A stale `user_settings.cfg` will silently pin `vid_renderer` and the
control layout; delete it to fall back to defaults.

## Online multiplayer (GnuTLS for the broker's TLS/DTLS)
NZ:P's online play goes through FTE's ICE broker (`tls://master.frag-net.com`),
which requires DTLS, and FTE's only crypto backend is GnuTLS, `dlopen`'d at
runtime and absent on Android. So it is cross-compiled for arm64 and bundled:

- `gnutls-android/build-{gmp,nettle,gnutls}.sh` build the chain with the NDK
  clang under MSYS2: GMP (`--disable-assembly`) -> Nettle (real GMP) -> GnuTLS
  (minimal: bundled libtasn1/unistring, no p11-kit/idn/doc/tools), with GMP and
  Nettle **static-linked** into one self-contained `libgnutls.so` whose only
  NEEDED entries are libc and libdl.
- Built with `-Wl,-z,max-page-size=16384`, so its LOAD segments are 16 KB
  aligned. Devices with 16 KB pages reject 4 KB-aligned libraries, which is what
  made `dlopen` fail.
- Vendored at `app/src/main/jniLibs/arm64-v8a/libgnutls.so` with headers in
  `app/gnutls-include/`.
- Build wiring: `-DFTE_DEP_GNUTLS=false`, so CMake's failing `FIND_PACKAGE`
  doesn't go on to define `NO_GNUTLS`.
- At runtime the engine falls back from the versioned soname
  (`libgnutls.so.30`, which an APK cannot carry) to the bare `libgnutls.so`.

Joining a Windows host additionally needs the DTLS role fix in the engine fork:
FTE's SChannel backend cannot act as a DTLS *server*, so the Android side always
offers `a=setup:passive` and forces the peer to be the client.

### LAN discovery
`masters.txt` in the game data adds a `bcast` master, so the Co-op browser's
refresh broadcasts a query across the local network and lists LAN servers.
