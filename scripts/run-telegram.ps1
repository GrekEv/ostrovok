$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "Островок как Telegram Mini App" -ForegroundColor Green
Write-Host ""
Write-Host "1) В этом же окне сейчас можно поднять туннель."
Write-Host "   API должен уже работать: .\scripts\run-backend.ps1"
Write-Host "   Проверка: http://127.0.0.1:8080"
Write-Host ""
Write-Host "2) @BotFather → /newbot → /newapp → Web App URL = https://…trycloudflare.com/"
Write-Host ""

$cloudflared = Get-Command cloudflared -ErrorAction SilentlyContinue
if (-not $cloudflared) {
    Write-Host "cloudflared не найден. Установка:"
    Write-Host "  winget install --id Cloudflare.cloudflared -e"
    Write-Host "Потом снова запустите этот скрипт."
    exit 1
}

Write-Host "Туннель на http://127.0.0.1:8080 — скопируйте https-адрес из лога."
& cloudflared tunnel --url http://127.0.0.1:8080
