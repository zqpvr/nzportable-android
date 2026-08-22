# Nazi Zombies: Portable for Android

An unofficial Android port of [Nazi Zombies: Portable](https://github.com/nzp-team/nzportable),
the Call of Duty Zombies de-make built on a fork of Spike's FTEQW engine. This is a native
arm64 build of the real engine rather than a wrapper or an emulator, so it runs the same game
code the desktop builds do, including cross-platform online play against PC hosts.

Signed APKs are published on the [releases page](https://github.com/zqpvr/nzportable-android/releases).
The game data is bundled inside the APK and unpacked on first launch, so there is nothing to
side-load or copy across; install it and it runs.

## What works

The engine renders through Vulkan by default with an OpenGL ES path kept as a fallback, and
the renderer can be switched from the video menu without touching a config file. Audio goes
through the low-latency AudioTrack path, the display is driven in immersive fullscreen with
cutout passthrough, and settings persist between runs.

Controls cover both ends. Bluetooth and USB controllers are supported with bindings that match
the desktop build, glyph prompts, aim assist, stick menu navigation and B-to-go-back, and a
full on-screen touch scheme is drawn by the client for everyone else: a movement stick under
the left thumb, drag-to-look on the right, and an aim-and-fire button that raises the sights
before it shoots and adapts to the weapon in hand. Full-autos hold, semi-autos tap at a
deliberate rate, scoped snipers and rocket launchers fire on release, and weapons with no
sights fire the moment you press. The two input schemes are independent; picking up a
controller hides the on-screen pad and touching the screen brings it back.

Online multiplayer works in both directions against a Windows host. NZ:P's matchmaking runs
over FTE's ICE broker, which requires DTLS, and FTE only implements that through GnuTLS, so a
self-contained arm64 GnuTLS is cross-compiled and bundled here. Joining a PC host additionally
needed an engine fix: FTE's Windows SChannel backend cannot act as a DTLS *server*, so the
Android side always takes the DTLS server role during SDP negotiation regardless of who hosts
the game.

## Building

The build drives CMake and the NDK through Gradle rather than the engine's legacy `make droid`
path. It needs JDK 17 (newer JDKs are too new for the Gradle version in use) and NDK
26.3.11579264; `compileSdk` is 34 and `minSdk` is 24, which covers arm64 devices with GLES2.

```bash
./gradlew :app:assembleDebug
```

Release builds are signed from an environment-driven keystore, so `assembleRelease` picks up
`KEYSTORE_FILE`, `KEYSTORE_PASSWORD`, `KEY_ALIAS` and `KEY_PASSWORD` and falls back to the debug
signing config when they are absent.

Changes to the engine and to the game code are kept as patches rather than as forks. The
`fteqw` submodule stays on upstream and `patches/0001-fteqw-android-build.patch` is applied to
the working tree; the QuakeC lives in `patches/0002-nzp-quakec.patch`, with
`patches/0002-base.txt` recording the upstream commit it was written against. A GitHub Actions
workflow rebuilds the signed APK weekly against the latest NZ:P data and game code, and if the
QuakeC patch ever stops applying to upstream's tip it rebuilds at that recorded base instead of
shipping stale code.

## Licensing

GPL-2.0, inherited from FTEQW and NZ:P. The on-screen control artwork is taken from glKarin's
[Diii4a / idTech4A++](https://github.com/glKarin/com.n0n3m4.diii4a), which is GPL-3.0; the
movement stick and the remaining touch icons were made for this port. NZ:P's own game assets
remain under the terms set by the NZ:P team.

This port is not affiliated with or endorsed by the NZ:P team. Please direct bug reports here
rather than to them.
