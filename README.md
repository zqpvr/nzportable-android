# Nazi Zombies: Portable for Android

Call of Duty Zombies, on a phone, without a controller.

[Nazi Zombies: Portable](https://github.com/nzp-team/nzportable) is a de-make of
the Zombies mode built on Spike's FTEQW engine. This is a native arm64 build of
that engine, not a wrapper or an emulator, so it runs the same game code the
desktop builds do.

The game data is inside the APK and is read from there, so there is nothing to
unpack, side-load or copy across.

Signed builds are on the [releases page](https://github.com/zqpvr/nzportable-android/releases).

## Features

- On-screen controls drawn by the game: a stick that anchors wherever your thumb
  lands, drag-to-look, and eleven action buttons.
- One shoot button that raises the sights before it fires and adapts to the
  weapon, rather than a fire button and an aim button.
- Running is automatic. Push the stick forward and you sprint.
- Bluetooth and USB controllers, with desktop-matching binds, glyph prompts and
  stick menu navigation. Picking one up hides the on-screen pad.
- Cross-platform online play against a Windows host, both hosting and joining.
- Vulkan by default, OpenGL ES as a fallback, switchable from the video menu
  without editing a config.
- Realtime lighting that lights the world from the map's own light entities.
- Automated builds, released only once every map loads with the game code and
  data going into them.

## Requirements

An arm64 device on Android 7.0 or newer, and about 125 MB of space: the APK is
all there is, since the game data is read from inside it.

Vulkan 1.2 is used when the driver offers it, which is most devices from the
last few years. Anything older falls back to OpenGL ES 2.

## Controls

The left half of the screen is the stick, the right half is look. Neither has a
fixed position; both work from wherever you touch.

| Button | Does |
| --- | --- |
| Aim-fire | Raises the sights, then fires. Drag off it to keep aiming while shooting |
| Reload | Reloads, and running waits until it has finished |
| Knife | Melee |
| Grenade | Throws the grenade you have selected |
| Grenade swap | Switches between frag and monkey bomb |
| Betty | Places a Bouncing Betty |
| Use | Doors, wall buys, perk machines, the box |
| Swap | Switches between your two weapons |
| Jump | Jumps |
| Crouch | Changes stance, or dolphin dives if you are sprinting |
| Pause | Opens the menu |

Shooting follows the weapon rather than one rule for everything. Full-autos fire
while held. Semi-autos, grenades, blades and the ray gun tap at a deliberate
rate instead of as fast as the button can be sampled. Scoped snipers and rocket
launchers hold the sights and fire when released, and a quick tap fires them
from the hip. Weapons with no sights fire the moment you press.

## How it works

The engine and the game code are forks of NZ:P's, [fteqw](https://github.com/zqpvr/fteqw)
and [quakec](https://github.com/zqpvr/quakec), each on an `android` branch. Their
changes are ordinary commits rather than patch files, so they can be read and
reverted individually.

| Piece | Where it comes from |
| --- | --- |
| Engine | `fteqw` submodule, our fork |
| Game code | `quakec` submodule, our fork, on the last upstream commit FTE can run |
| Game data | NZ:P's assets from their last FTE build, packed into the APK and read in place |
| TLS | GnuTLS, cross-compiled for arm64 and vendored |

NZ:P's PC build moved from FTE to its own Vril engine in September 2026, and the
game code and assets moved with it: upstream's `progs.dat` now calls builtins
FTE doesn't have, and FTE's particles, shaders, menu art and Ogg music are gone
from its data. So both are pinned to the last FTE build, quakec 6ed6305 and
assets c5a1d8070b.

The data sits in the root of the APK, which the engine already mounts as a pack,
so it is read in place rather than unpacked to storage.

Online play goes through FTE's ICE broker, which requires DTLS, and FTE's only
crypto backend is GnuTLS, `dlopen`'d at runtime and absent on Android. So it is
cross-compiled here, with GMP and Nettle static-linked into one 2.7 MB library
whose only dependencies are libc and libdl. It is built with 16 KB page
alignment, because devices with 16 KB pages reject a 4 KB-aligned library and
that is what made `dlopen` fail.

Joining a Windows host needed an engine fix as well. FTE's SChannel backend
cannot act as a DTLS *server*, so the Android side always offers
`a=setup:passive` and makes the peer be the client.

The touch controls live in the game code rather than the engine, so they are
drawn and driven by the same layer that draws the HUD. Touch reports `K_TOUCH`,
which the menu system does not recognise as a click, so it is translated into
the mouse events the menus already understand.

## Building

Needs JDK 17, since newer JDKs are too new for the Gradle version in use, and
NDK 26.3.11579264. `compileSdk` is 34 and `minSdk` is 24.

The game data isn't tracked. `tools/build-data.sh` assembles it into `nzp/`,
downloading NZ:P's assets and building the game code from `quakec/`, which needs
a python3 with pandas, fastcrc and colorama.

```bash
git submodule update --init
tools/build-data.sh
./gradlew :app:assembleDebug
```

Release builds are signed from the environment, so `assembleRelease` reads
`KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD`, and falls
back to debug signing when they are absent.

A workflow rebuilds the signed APK weekly and publishes it, but only after a
headless server built from the same engine has loaded every map with the same
game code and data (`tools/smoke-test.sh`).

The APK ships a stripped library, so a native crash arrives as bare offsets. The
unstripped one is kept as a build artifact, stamped with its GNU build ID, so a
tombstone can be resolved against the exact binary it came from.

## Layout

```
app/
  build.gradle          SDK levels, signing, CMake and NDK wiring
  src/main/resources/   our files packed next to the game data: config, server
                        list and touch art
  src/main/jniLibs/     libgnutls.so
fteqw/                  the engine, a submodule pointing at our fork
gnutls-android/         cross-compile scripts for GMP, Nettle and GnuTLS
nzp/                    the game data, from tools/build-data.sh (not tracked)
quakec/                 the game code, a submodule pointing at our fork
tools/                  build-data.sh and smoke-test.sh
```

## Licence

GPL-2.0, inherited from FTEQW and NZ:P, see [LICENSE](LICENSE). The on-screen
button artwork is from glKarin's
[Diii4a](https://github.com/glKarin/com.n0n3m4.diii4a), which is GPL-3.0. The
movement stick and the remaining icons were drawn for this port. NZ:P's own
assets stay under the terms the NZ:P team set.

Not affiliated with or endorsed by the NZ:P team. Report problems here rather
than to them.
