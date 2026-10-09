#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/backend"

if ! command -v go >/dev/null 2>&1; then
  echo "Go не найден. Установите: brew install go" >&2
  exit 1
fi

echo "Островок API: http://127.0.0.1:8080"
echo "Остановка: Ctrl+C"
exec go run ./cmd/api
