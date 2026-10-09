# Тест в Telegram Mini App

Самый простой способ дать потыкать Островок с телефона: мини-приложение внутри Telegram. Ставить APK и ходить в App Store не нужно.

Telegram открывает обычный сайт по HTTPS. Карточки и свайпы идут в тот же Go API (`POST /v1/swipes` → Postgres).

## 1. Запустите API

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-local.ps1
```

Проверка: http://127.0.0.1:8080/ и http://127.0.0.1:8080/health (`"store":"postgresql"`). Полный разбор запуска и токенов: [LAUNCH.md](LAUNCH.md).

## 2. Дайте сайту HTTPS-адрес

Telegram **не откроет** `http://127.0.0.1`. Нужен туннель.

Установите Cloudflare Tunnel:

```powershell
winget install --id Cloudflare.cloudflared -e
```

Новый терминал:

```powershell
cloudflared tunnel --url http://127.0.0.1:8080
```

В логе появится адрес вида `https://something.trycloudflare.com`. Это и есть ссылка мини-приложения. Добавьте `/app/` в конец, если открываете из браузера: `https://something.trycloudflare.com/app/`

## 3. Привяжите бота

1. В Telegram откройте [@BotFather](https://t.me/BotFather).
2. `/newbot` — имя и username (например `ostrovok_demo_bot`).
3. Сохраните токен, в код его класть не обязательно.
4. `/newapp` — выберите бота → название «Островок» → в **Web App URL** вставьте `https://something.trycloudflare.com/`.
5. Откройте своего бота → кнопку меню Mini App или ссылку, которую выдаст BotFather (`t.me/ваш_бот/имя_приложения`).

Свайп вправо/влево должен сменить карточку и строку статуса «лайк записан в Postgres».

## Что увидят тестеры

Открывают бота в Telegram и запускают мини-приложение. Гость берётся из аккаунта Telegram (`tg-123456`). Онбординг пропускается, сразу колода.

Пока туннель запущен на вашем компьютере, ссылка жива. Выключили ноутбук — мини-приложение недоступно.
