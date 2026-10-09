param(
    [string]$ApiUrl = "",
    [string]$Device = ""
)

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
$portableGit = Join-Path $root ".tools\git\cmd"

if (Test-Path (Join-Path $portableGit "git.exe")) {
    $env:PATH = "$portableGit;$env:PATH"
}

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    $flutter = "flutter"
} elseif (Test-Path $portableFlutter) {
    $flutter = $portableFlutter
} else {
    throw "Flutter was not found. See docs/FLUTTER.md."
}

Set-Location $mobile
& $flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$arguments = @("run")
if (-not $Device) {
    $deviceList = & $flutter devices
    if ($deviceList -match 'emulator-' -or $deviceList -match 'sdk gphone' -or $deviceList -match 'Pixel') {
        $Device = ""
    } elseif ($deviceList -match 'edge') {
        $Device = "edge"
    }
}
if ($Device) {
    $arguments += @("-d", $Device)
}
if ($ApiUrl) {
    $arguments += "--dart-define=OSTROVOK_API_URL=$ApiUrl"
}

& $flutter @arguments
