#!/usr/bin/env bash
# Regenerates the manager's generated theme resources, replacing the
# dev.rikka.tools.materialthemebuilder Gradle plugin.
#
# Why: that plugin resolves AGP's legacy BaseExtension, which AGP 9 removed, so applying it fails
# configuration ("Extension of type 'BaseExtension' does not exist") and nothing in the module
# builds. This script compiles scripts/dev/palette/GenerateTheme.java against the vendored
# material-color-utilities sources (scripts/dev/palette/mcu) and writes:
#
#   manager/build/generated/themeRes/values/values.xml
#   manager/build/generated/themeRes/values-v31/values.xml
#   manager/build/generated/themeRes/values/themes_accents.xml
#
# manager/build.gradle adds that directory to the main source set; the files are build output, not
# checked in. Run this script by hand only to inspect the resources.
#
# Usage: bash scripts/dev/gen-theme-res.sh [out-dir]
set -euo pipefail
cd "$(dirname "$0")/../.."

OUT="${1:-manager/build/generated/themeRes}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v javac >/dev/null 2>&1; then
    echo "✗ javac not found; a JDK 17+ is required" >&2
    exit 1
fi

find scripts/dev/palette/mcu -name '*.java' > "$WORK/sources.txt"
echo "scripts/dev/palette/GenerateTheme.java" >> "$WORK/sources.txt"

javac -nowarn -d "$WORK/out" @"$WORK/sources.txt"
java -cp "$WORK/out" GenerateTheme "$OUT"
