$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$pgHomeProject = Join-Path $root ".tools\pgsql\postgresql-15.10.0-x86_64-pc-windows-msvc"
$pgHome = Join-Path $env:LOCALAPPDATA "Ostrovok\pgsql"
# PostgreSQL initdb ломается на кириллице в пути (D:\Разработка\...).
$pgData = Join-Path $env:LOCALAPPDATA "Ostrovok\pgdata"
$pwFile = Join-Path $env:LOCALAPPDATA "Ostrovok\pgpass.txt"
New-Item -ItemType Directory -Path (Split-Path $pgData) -Force | Out-Null
if (-not (Test-Path (Join-Path $pgHome "bin\postgres.exe"))) {
    if (-not (Test-Path (Join-Path $pgHomeProject "bin\postgres.exe"))) {
        throw "Не найдены бинарники PostgreSQL."
    }
    Write-Host "Копирую PostgreSQL в ASCII-путь $pgHome ..."
    robocopy $pgHomeProject $pgHome /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "Не удалось скопировать PostgreSQL (robocopy $LASTEXITCODE)" }
}
$pgBin = Join-Path $pgHome "bin"
$port = 5432
if ($env:OSTROVOK_POSTGRES_PORT) { $port = [int]$env:OSTROVOK_POSTGRES_PORT }

$env:Path = "$pgBin;$env:Path"
$env:PGPASSWORD = "super_secret_password"
$pgPass = Join-Path $env:LOCALAPPDATA "Ostrovok\pgpass.conf"
@(
    "127.0.0.1:${port}:*:ostrovok_user:super_secret_password",
    "localhost:${port}:*:ostrovok_user:super_secret_password"
) | Set-Content -Path $pgPass -Encoding ascii
$env:PGPASSFILE = $pgPass

if (-not (Test-Path (Join-Path $pgBin "postgres.exe"))) {
    throw "Не найдены бинарники PostgreSQL в $pgBin. Скачайте их в .tools/pgsql."
}

$alreadyOurs = $false
& "$pgBin\pg_isready.exe" -h 127.0.0.1 -p $port 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { $alreadyOurs = $true }
$inUse = $false
try {
    $inUse = [bool](Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue)
} catch {
    $inUse = $false
}

if (-not $alreadyOurs) {
    if ($inUse) {
        $port = 55432
        Write-Host "Порт 5432 занят, используем $port"
    }
    New-Item -ItemType Directory -Path $pgData -Force | Out-Null
    Set-Content -Path $pwFile -Value "super_secret_password" -NoNewline -Encoding ascii
    $marker = Join-Path $pgData "PG_VERSION"
    if (-not (Test-Path $marker)) {
        Write-Host "Инициализация PostgreSQL..."
        & "$pgBin\initdb.exe" -D $pgData -U ostrovok_user --pwfile=$pwFile --auth=password -E UTF8 --locale=C | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "initdb завершился с кодом $LASTEXITCODE" }
    }
    $log = Join-Path (Split-Path $pgData) "postgres.log"
    Write-Host "Запуск PostgreSQL на порту $port..."
    & "$pgBin\pg_ctl.exe" -D $pgData -l $log -o "-p $port -h 127.0.0.1" start | Out-Host
    $ready = $false
    for ($i = 0; $i -lt 30; $i++) {
        & "$pgBin\pg_isready.exe" -h 127.0.0.1 -p $port | Out-Null
        if ($LASTEXITCODE -eq 0) { $ready = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $ready) { throw "PostgreSQL не поднялась. Лог: $log" }
}

$env:PGPASSWORD = "super_secret_password"
$exists = & "$pgBin\psql.exe" -w -h 127.0.0.1 -p $port -U ostrovok_user -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='ostrovok_travel'"
if ($LASTEXITCODE -ne 0) { throw "psql не подключается (код $LASTEXITCODE). Проверьте пароль ostrovok_user." }
if ("$exists".Trim() -ne "1") {
    & "$pgBin\createdb.exe" -w -h 127.0.0.1 -p $port -U ostrovok_user ostrovok_travel | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "createdb не удался" }
}

$sqlDir = Join-Path $root "backend\sql"
$files = @(
    "init.sql",
    "mock_data.sql",
    "02b-local-photos.sql",
    "03-app_extras.sql",
    "04-extra-cards.sql"
)
foreach ($name in $files) {
    $path = Join-Path $sqlDir $name
    Write-Host "SQL $name"
    & "$pgBin\psql.exe" -w -h 127.0.0.1 -p $port -U ostrovok_user -d ostrovok_travel -v ON_ERROR_STOP=1 -f $path | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "SQL $name завершился с кодом $LASTEXITCODE" }
}

$env:DATABASE_URL = "postgres://ostrovok_user:super_secret_password@127.0.0.1:${port}/ostrovok_travel?sslmode=disable"
Write-Host "DATABASE_URL=$env:DATABASE_URL"
Write-Output $env:DATABASE_URL
