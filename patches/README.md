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

## 0002-nzp-quakec-aimassist.patch
Applies to the **NZ:P QuakeC** game code (nzp-team/quakec), which is built
separately into `csprogs.dat`.
```
git clone https://github.com/nzp-team/quakec
cd quakec && git apply ../patches/0002-nzp-quakec-aimassist.patch
# build (Windows): tools\qc-compiler-win.bat  (csprogs.dat + menu.dat build
# without the python/pandas hash step; only the server progs need it)
cd bin && ./fteqcc-cli-win.exe -DFTE -Wall -srcfile ../progs/csqc.src
# then copy build/fte/csprogs.dat into app/src/main/assets/nzp/
```
Sets `gamepad_enabled` when controller input arrives — NZ:P never sets it, so
aim assist (gated on that flag) was dead even on desktop.
