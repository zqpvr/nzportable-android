# Nazi Zombies: Portable for Android

An Android port of Nazi Zombies: Portable, running the real FTEQW engine natively (not a wrapper).

This is an independent, unofficial project. It is **not** affiliated with, endorsed by, or
supported by the Nazi Zombies: Portable team or the FTEQW developers. It started as a port of
their open-source work and has grown into its own thing. Please don't bother them with issues
from this build — open them here instead.

## What works

- Runs on arm64 Android (built and tested on a Galaxy S23)
- Vulkan by default, with an OpenGL ES option in the video menu
- Touch menus and full controller support: binds match the desktop game, on-screen glyphs,
  aim assist, and the menus/server browser are gamepad-navigable
- Online multiplayer with desktop players, both hosting and joining, plus LAN games
- Immersive fullscreen, settings that save, low-latency audio

In-game touch controls aren't done yet — for now it's best with a controller.

## Game data

This repo does **not** include the game's data (maps, models, sounds, etc.) — that belongs to the
Nazi Zombies: Portable team. You provide it yourself: take the `nzp` folder from an official NZ:P
release and set it up at `app/src/main/assets/nzp/`. It gets packed into the APK and unpacked on
first launch. `patches/README.md` covers the exact data setup (including the game-code `.dat`
files you build from the QuakeC patch).

## Building

You need the Android SDK + NDK (26.3.x) and JDK 17. After placing the game data:

```sh
./gradlew :app:assembleDebug
```

The engine is the `fteqw` submodule, kept pristine — our changes to it live as patches in
`patches/` and are applied to the working tree. See `patches/README.md` for that and for the
game-code (QuakeC) changes.

## License

The FTEQW engine is GPL, so this project is GPL too — see [LICENSE](LICENSE). The bundled
`libgnutls.so` (used for encrypted multiplayer) is LGPL; the scripts to rebuild it are in
`gnutls-android/`. The game data is not covered by this license and is not distributed here.
