#!/usr/bin/env bash
# Assembles nzp/, the game data the APK carries: NZ:P's assets as of their last FTE build,
# the game code compiled from quakec/, and the version.txt the menu shows. Gradle packs it
# into the root of the APK along with app/src/main/resources/, and the engine reads it there.
#
# Needs curl, unzip, and a python3 with pandas, fastcrc and colorama. With faketime
# installed, the same quakec commit always builds the same bytes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/nzp"

# nzp-team/assets c5a1d8070b, the last commit before NZ:P's PC build moved from FTE to its
# own Vril engine, as its Asset Assembly workflow packaged it (run 33706329420). Upstream's
# copy expires with that run's artifacts, so it is kept as a release asset here.
ASSETS_URL="https://github.com/zqpvr/nzportable-android/releases/download/game-data/pc-nzp-assets-c5a1d8070b.zip"
ASSETS_SHA256="8af5a922a161ae94cd6ed2993841720ce5e8343b6e92ab3c5e55bcadda2511b8"
ZIP="${XDG_CACHE_HOME:-$HOME/.cache}/nzportable-android/${ASSETS_URL##*/}"

if ! echo "$ASSETS_SHA256  $ZIP" | sha256sum -c --status 2>/dev/null; then
    mkdir -p "$(dirname "$ZIP")"
    curl -fL --retry 3 -o "$ZIP.part" "$ASSETS_URL"
    echo "$ASSETS_SHA256  $ZIP.part" | sha256sum -c --quiet
    mv "$ZIP.part" "$ZIP"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
unzip -q "$ZIP" -d "$tmp"
rm -rf "$OUT"
mv "$tmp/nzp" "$OUT"

# our copies of these win, and Gradle refuses two files at one path
(cd "$ROOT/app/src/main/resources" && find . -type f) | (cd "$OUT" && xargs rm -f)

# the game code only ever plays a track's .ogg, and this engine reads .mp3 only on Windows
find "$OUT/tracks" -name "*.mp3" -exec sh -c 'for f; do [ ! -f "${f%.mp3}.ogg" ] || rm "$f"; done' sh {} +

# fteqcc stamps the date into every .dat, so pin it to the commit's: the same code then
# builds the same bytes, and a server built from it announces the same csprogs CRC
qc="$ROOT/quakec"
pin=()
if command -v faketime >/dev/null; then
    pin=(faketime "$(git -C "$qc" log -1 --format=%cd --date=iso)")
fi
run() { "$@" > "$tmp/log" 2>&1 || { cat "$tmp/log"; return 1; }; }
(
    cd "$qc"
    run python3 bin/qc_hash_generator.py -i tools/asset_conversion_table.csv -o source/server/hash_table.qc
    mkdir -p build/fte
    cd bin
    run "${pin[@]}" ./fteqcc-cli-lin -DFTE -srcfile ../progs/csqc.src
    run "${pin[@]}" ./fteqcc-cli-lin -DFTE -srcfile ../progs/menu.src
    run "${pin[@]}" ./fteqcc-cli-lin -O3 -DFTE -srcfile ../progs/ssqc.src
)
cp "$qc"/build/fte/{csprogs,menu,qwprogs}.dat "$OUT/"

echo "${BUILD_NAME:-local build}" > "$OUT/version.txt"
echo "nzp/: $(find "$OUT" -type f | wc -l) files, $(du -sh "$OUT" | cut -f1)"
