$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

if ($root -match '[^\x00-\x7F]') {
    if (-not (Test-Path 'Z:\')) {
        subst Z: $root | Out-Null
    }
    $root = 'Z:\'
}

$mobile = Join-Path $root "mobile"
$portableFlutter = Join-Path $root ".tools\flutter\bin\flutter.bat"
$portableDart = Join-Path $root ".tools\flutter\bin\dart.bat"
$portableGit = Join-Path $root ".tools\git\cmd"

if (Test-Path (Join-Path $portableGit "git.exe")) {
    $env:PATH = "$portableGit;$env:PATH"
}

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutter = "flutter"
    $dart = "dart"
} elseif (Test-Path $portableFlutter) {
    $flutter = $portableFlutter
    $dart = $portableDart
} else {
    throw "Flutter was not found. See docs/FLUTTER.md."
}

Set-Location $mobile
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $dart format --set-exit-if-changed lib test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $dart analyze lib test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& $flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Flutter format, analyze and tests passed." -ForegroundColor Green
