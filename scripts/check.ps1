$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $root "backend"
$portableBin = Join-Path $root ".tools\go\bin"

if (Get-Command go -ErrorAction SilentlyContinue) {
    $go = "go"
    $gofmt = "gofmt"
} elseif (Test-Path (Join-Path $portableBin "go.exe")) {
    $go = Join-Path $portableBin "go.exe"
    $gofmt = Join-Path $portableBin "gofmt.exe"
} else {
    throw "Go was not found. Install it: winget install --id GoLang.Go --exact"
}

Set-Location $backend
$files = Get-ChildItem -Recurse -Filter "*.go" | ForEach-Object FullName
& $gofmt -w $files
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $go vet ./...
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& $go test ./...
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Go formatting, vet and tests passed." -ForegroundColor Green
