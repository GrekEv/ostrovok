$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$portableGit = Join-Path $root ".tools\git\cmd"
if (Test-Path (Join-Path $portableGit "git.exe")) {
    $env:PATH = "$portableGit;$env:PATH"
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git не найден. Установите Git for Windows или используйте .tools\git."
}

function Ensure-Gh {
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        return
    }
    Write-Host "Устанавливаю GitHub CLI..."
    winget install --id GitHub.cli -e --accept-package-agreements --accept-source-agreements
    $ghPaths = @(
        "$env:ProgramFiles\GitHub CLI",
        "${env:ProgramFiles(x86)}\GitHub CLI",
        "$env:LocalAppData\GitHub CLI"
    )
    foreach ($dir in $ghPaths) {
        if (Test-Path (Join-Path $dir "gh.exe")) {
            $env:PATH = "$dir;$env:PATH"
        }
    }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI установлен, но не виден в PATH. Закройте терминал, откройте новый и снова запустите скрипт."
    }
}

Ensure-Gh

$auth = & gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Нужен вход в GitHub. Сейчас откроется браузер."
    & gh auth login --hostname github.com --git-protocol https --web
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Set-Location $root
if (-not (Test-Path (Join-Path $root ".git"))) {
    & git init -b main
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$login = (& gh api user --jq .login).Trim()
if (-not $login) { throw "Не удалось узнать логин GitHub." }
$email = "$login@users.noreply.github.com"
$repoName = "ostrovok"

& git add -A
$status = & git status --porcelain
if ($status) {
    & git -c "user.name=$login" -c "user.email=$email" commit -m "Publish Ostrovok web demo on GitHub Pages."
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$existing = ""
try { $existing = (& git remote get-url origin 2>$null | Out-String).Trim() } catch { }

if (-not $existing) {
    Write-Host "Создаю публичный репозиторий $login/$repoName ..."
    & gh repo create $repoName --public --source $root --remote origin --push
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Репозиторий, возможно, уже есть. Подключаю origin и отправляю код..."
        & git remote add origin "https://github.com/$login/$repoName.git" 2>$null
        & git push -u origin main
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
} else {
    & git push -u origin main
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

try {
    & gh api -X POST "repos/$login/$repoName/pages" -f build_type=workflow 2>$null | Out-Null
} catch {
}

Write-Host ""
Write-Host "Код:     https://github.com/$login/$repoName"
Write-Host "Тестерам: https://$login.github.io/$repoName/"
Write-Host "Сборка:  https://github.com/$login/$repoName/actions"
Write-Host ""
Write-Host "Подождите 2–5 минут, пока во вкладке Actions появится зелёная галочка."
