$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "=== Островок: локальный запуск ===" -ForegroundColor Green

if (Get-Command docker -ErrorAction SilentlyContinue) {
    Write-Host "Docker найден — поднимаю compose (Postgres + API)..."
    docker compose up --build -d
    for ($i = 0; $i -lt 40; $i++) {
        try {
            $health = Invoke-RestMethod "http://127.0.0.1:8080/health" -TimeoutSec 2
            if ($health.store -eq "postgresql") {
                Write-Host "API готов: http://127.0.0.1:8080/  store=$($health.store)"
                exit 0
            }
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    Write-Warning "Compose поднялся, но /health ещё не postgresql. Смотрите docker compose logs api"
    exit 1
}

Write-Host "Docker не установлен — поднимаю локальный PostgreSQL 15 и Go API."
& (Join-Path $PSScriptRoot "ensure-postgres.ps1")
if (-not $env:DATABASE_URL) {
    $env:DATABASE_URL = "postgres://ostrovok_user:super_secret_password@127.0.0.1:5432/ostrovok_travel?sslmode=disable"
}

$backend = Join-Path $root "backend"
$portableGo = Join-Path $root ".tools\go\bin\go.exe"
$go = "go"
if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    if (Test-Path $portableGo) { $go = $portableGo } else { throw "Не найден Go. Установите: winget install --id GoLang.Go --exact" }
}

Write-Host "API: http://127.0.0.1:8080/"
Write-Host "Остановка: Ctrl+C"
Set-Location $backend
& $go run ./cmd/api
