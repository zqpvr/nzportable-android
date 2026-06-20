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

