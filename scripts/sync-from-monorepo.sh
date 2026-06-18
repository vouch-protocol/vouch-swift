#!/usr/bin/env bash
#
# Sync the published Swift SDK in this repo from the canonical copy in the Vouch
# monorepo (sdks/swift/). The monorepo is the source of truth; this repo exists
# only because Swift Package Manager requires Package.swift at the repo root and
# cannot import a package from a monorepo subdirectory.
#
# What it copies (one-way, monorepo -> here):
#   Package.swift, Sources/, Tests/, ffi/, build-xcframework.sh
#
# What it deliberately does NOT touch (repo-specific files):
#   README.md, LICENSE, .gitignore, .github/, scripts/
#
# Usage:
#   scripts/sync-from-monorepo.sh [path-to-monorepo]
#   MONOREPO=/path/to/vouch scripts/sync-from-monorepo.sh
#
# Default monorepo path is a sibling directory named "vouch-protocol".
#
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
monorepo="${1:-${MONOREPO:-$here/../vouch-protocol}}"
src="$monorepo/sdks/swift"

if [ ! -f "$src/Package.swift" ]; then
  echo "error: cannot find $src/Package.swift" >&2
  echo "       point this script at the monorepo: scripts/sync-from-monorepo.sh /path/to/vouch" >&2
  exit 1
fi

echo "==> syncing from $src"

# Manifest and build script: straight copies.
cp "$src/Package.swift"          "$here/Package.swift"
cp "$src/build-xcframework.sh"   "$here/build-xcframework.sh"
chmod +x "$here/build-xcframework.sh"

# Source trees: mirror exactly, dropping files removed upstream.
for dir in Sources Tests ffi; do
  rm -rf "${here:?}/$dir"
  mkdir -p "$here/$dir"
  cp -R "$src/$dir/." "$here/$dir/"
done

echo "==> done. Review changes, then commit + tag:"
echo "    git -C \"$here\" status"
echo "    git -C \"$here\" add -A && git -C \"$here\" commit -m 'Sync Swift SDK from monorepo'"
echo "    git -C \"$here\" tag 0.1.0 && git -C \"$here\" push --tags"
