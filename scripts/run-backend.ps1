$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"
$portableGo = Join-Path $root ".tools\go\bin\go.exe"

if (Get-Command go -ErrorAction SilentlyContinue) {
    $go = "go"
} elseif (Test-Path $portableGo) {
    $go = $portableGo
} else {
    Write-Error @"
Go was not found.
Install it: winget install --id GoLang.Go --exact
Then restart PowerShell.
"@
}

if (-not $env:DATABASE_URL) {
    $env:DATABASE_URL = "postgres://ostrovok_user:super_secret_password@127.0.0.1:5432/ostrovok_travel?sslmode=disable"
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Starting PostgreSQL via Docker..."
    docker compose up -d postgres_db
}

Set-Location $backend
Write-Host "Ostrovok API: http://127.0.0.1:8080" -ForegroundColor Green
Write-Host "Stop: Ctrl+C"
& $go run ./cmd/api
