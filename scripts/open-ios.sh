#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "iOS-проект можно открыть только на macOS с Xcode." >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
open "$ROOT/ios/Ostrovok/Ostrovok.xcodeproj"
