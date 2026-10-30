#!/usr/bin/env bash
# Loads every map in nzp/ on a dedicated server built from this engine with the APK's
# config, and fails on any error. Compiling the game code and linking the engine prove
# nothing about whether they agree: a builtin the engine lacks only fails when the server
# runs it, and that once shipped weeks of releases that couldn't load a map.
#
# Needs make, a C compiler and zlib's headers, and nzp/ from tools/build-data.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
make -C "$ROOT/fteqw/engine" -j"$(nproc)" sv-rel FTE_TARGET=linux64 FTE_CONFIG=nzportable > /dev/null
SV="$ROOT/fteqw/engine/release/nzportable-sv64"

# Run on a copy of what the APK carries: the server writes configs next to the data, and
# one left in nzp/ would be packed and pin settings.
base="$(mktemp -d)"
trap 'rm -rf "$base"' EXIT
cp -r "$ROOT/nzp" "$base/nzp"
cp -r "$ROOT/app/src/main/resources/." "$base/nzp/"
printf 'game nzp\nbasegame nzp\nmainconfig "nzportable.cfg"\ndisablehomedir 1\n' > "$base/nzp.fmf"

failed=0
for bsp in "$base"/nzp/maps/*.bsp; do
    map=$(basename "$bsp" .bsp)
    rc=0
    # deathmatch 0, as solo and co-op run, which is also when a stray progs.dat would win
    out=$(cd "$base" && timeout 60 "$SV" -nohome -basedir . -manifest nzp.fmf +sv_public 0 \
            +developer 1 +deathmatch 0 +map "$map" +wait +wait +status +wait +wait +quit 2>&1) || rc=$?
    if [ "$rc" -eq 0 ] && grep -q "current map *: $map" <<< "$out" \
         && grep -q "Loaded progs qwprogs.dat" <<< "$out" \
         && ! grep -qE "SV_Error|not implemented|not compatible" <<< "$out"; then
        echo "ok   $map"
    else
        echo "FAIL $map (exit $rc)"
        grep -E "SV_Error|not implemented|not compatible|Error|progs" <<< "$out" | head -5 || true
        failed=1
    fi
done
exit "$failed"
