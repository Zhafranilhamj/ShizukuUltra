#!/usr/bin/env bash
# Kept for the --compare mode only. The accents themselves are now generated together with the rest
# of the theme resources by scripts/dev/gen-theme-res.sh (scripts/dev/palette/GenerateTheme.java),
# because that reads the vendored material-color-utilities (scripts/dev/palette/mcu) instead of
# MDC's cached AAR classes.
#
# Usage: bash scripts/dev/gen-accent-palettes.sh --compare  # print seeds under each variant
set -euo pipefail
cd "$(dirname "$0")/../.."

MDC_VERSION="$(sed -n 's/^material = "\(.*\)"/\1/p' gradle/libs.versions.toml)"
AAR="$(find "${GRADLE_USER_HOME:-$HOME/.gradle}/caches/modules-2/files-2.1/com.google.android.material/material/${MDC_VERSION}" -name "material-${MDC_VERSION}.aar" 2>/dev/null | head -1)"
if [[ -z "$AAR" ]]; then
    echo "✗ material-${MDC_VERSION}.aar is not in the Gradle cache; run a build first." >&2
    exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
unzip -q -o "$AAR" classes.jar -d "$WORK"
javac -nowarn -d "$WORK/out" -cp "$WORK/classes.jar" scripts/dev/palette/GenerateAccents.java
if [[ "${1:-}" == "--compare" ]]; then
    java -cp "$WORK/out:$WORK/classes.jar" GenerateAccents --compare "${@:2}"
else
    java -cp "$WORK/out:$WORK/classes.jar" GenerateAccents > manager/src/main/res/values/themes_accents.xml
    echo "▸ wrote manager/src/main/res/values/themes_accents.xml (MDC ${MDC_VERSION})"
fi
