# Как запустить Островок локально

Нужны **Go 1.22+** и **PostgreSQL**. Предпочтительно Docker — так же, как у жюри. Если Docker ещё не установлен, скрипт поднимает локальную PostgreSQL 15 в `%LOCALAPPDATA%\Ostrovok` (кириллица в `D:\Разработка` ломает `initdb`).

## 1. Самый короткий путь (Windows)

Из корня проекта:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-local.ps1
```

Откройте в браузере:

- приложение: http://127.0.0.1:8080/
- проверка базы: http://127.0.0.1:8080/health

В `/health` должно быть `"store":"postgresql"`. Если там `memory` или ошибка запуска — база не подключена, для защиты это не подходит.

Остановка API: `Ctrl+C` в том же окне.

## 2. Как у жюри — Docker Compose

Установите [Docker Desktop](https://www.docker.com/products/docker-desktop/) и WSL2, затем:

```powershell
docker compose up --build
```

Сброс базы (если меняли SQL):

```powershell
docker compose down -v
docker compose up --build
```

## 3. Что проверить за 2 минуты

1. Карточка с **фото** (не страница Unsplash).
2. Свайп вправо → статус «Свайп учтён», вкладка **Сохранено** показывает место с сервера.
3. Следующая карточка **другая**; в тексте рекомендации есть пересчёт тегов PostgreSQL.
4. Вкладка **AI-помощник**: «Хочу море до 10000» — ответ и кнопки вариантов из каталога.
5. Повторный `/health` по-прежнему `"store":"postgresql"`.

Автотест того же пути:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\e2e-api.ps1
```

Юнит-тесты Go (без Docker):

```powershell
cd backend
go test ./...
```

## 4. Telegram Mini App

1. Запустите API как выше.
2. Выложите его по HTTPS (туннель `scripts/run-telegram.ps1` или сервер).
3. В BotFather укажите URL Web App на корень сайта (`https://…/`).
4. Задайте `TELEGRAM_BOT_TOKEN` — сервер проверит подпись `Telegram.WebApp.initData`.
5. Для жёсткой проверки без браузерного обхода: `TELEGRAM_REQUIRE_INITDATA=true`.

Локальный браузер без Telegram работает без токена.

## 5. Живой LLM (необязательно)

Без ключа помощник ищет по Postgres правилами и фильтрами (город, бюджет). Этого достаточно для демо.

Чтобы подключить модель, **не выдумывайте ключ** — вставьте свой:

```powershell
$env:OPENAI_API_KEY="sk-..."
# или совместимый шлюз:
$env:OSTROVOK_LLM_API_KEY="..."
$env:OSTROVOK_LLM_BASE_URL="https://api.openai.com/v1"
$env:OSTROVOK_LLM_MODEL="gpt-4o-mini"
```

## 6. Flutter-клиент (по желанию)

```powershell
.\scripts\run-local.ps1
.\scripts\run-mobile.ps1
```

Подробности: [TESTING.md](TESTING.md), [TELEGRAM.md](TELEGRAM.md), [INSTALL.md](INSTALL.md).
