# Полная инструкция: запуск Островка для себя и для жюри

Это канонический документ. Если что-то расходится с README — верьте этому файлу.

Цель защиты: **живой путь**  
телефон / браузер → `POST /v1/swipes` → строка в PostgreSQL `user_swipes` → SQL пересчёт тегов → новая карточка.  
В `GET /health` обязательно `"store":"postgresql"`. Режим памяти (`OSTROVOK_ALLOW_MEMORY=true`) для жюри **не использовать**.

---

## 1. Что из чего состоит

| Процесс | Зачем | Порт |
|---|---|---|
| PostgreSQL 15 | Карточки, свайпы, рекомендации, сохранённое | `5432` |
| Go API | Mini App, JSON API, фото `/static/places` | `8080` |
| Redis | В compose есть, API его **не требует** | `6379` |
| Браузер / Telegram | Клиент для демо | — |

Клиенты:

- **Для жюри удобнее всего:** Telegram Mini App или браузер на http://127.0.0.1:8080/
- Flutter `mobile/` — отдельный клиент, тот же API
- iOS SwiftUI — только macOS, для защиты не нужен

Код: https://github.com/GrekEv/ostrovok

---

## 2. Что поставить

### Для жюри (как в критериях: Go + Postgres в Docker)

1. [Docker Desktop](https://www.docker.com/products/docker-desktop/) + WSL2 на Windows.
2. Git (чтобы клонировать репозиторий).
3. Браузер.

После установки Docker **перезапустите компьютер**, дождитесь кита в трее «Docker Desktop is running».

Проверка:

```powershell
docker version
docker compose version
```

### Для себя на этой машине (Docker может быть не установлен)

Нужны:

1. Go 1.22+: `winget install --id GoLang.Go --exact` и новый терминал.
2. Скрипт сам поднимет PostgreSQL 15 в `%LOCALAPPDATA%\Ostrovok` (кириллица в `D:\Разработка` ломает `initdb`, поэтому данные **не** кладутся в папку проекта).

Проверка Go:

```powershell
go version
```

---

## 3. Учётные данные базы (это не секрет жюри, это демо-логин)

Они **уже прописаны** в `docker-compose.yml` и в значении по умолчанию API. Выдумывать другие не нужно.

| Параметр | Значение |
|---|---|
| Хост из контейнера API | `postgres_db` |
| Хост с вашего ПК | `127.0.0.1` |
| Порт | `5432` |
| База | `ostrovok_travel` |
| Пользователь | `ostrovok_user` |
| Пароль | `super_secret_password` |
| SSL | выключен (`sslmode=disable`) |

Строка подключения с компьютера:

```text
postgres://ostrovok_user:super_secret_password@127.0.0.1:5432/ostrovok_travel?sslmode=disable
```

Строка внутри Docker (сервис `api`):

```text
postgres://ostrovok_user:super_secret_password@postgres_db:5432/ostrovok_travel?sslmode=disable
```

Это **учебные** реквизиты хакатона. На настоящем проде пароль меняют. Для защиты менять не обязательно: жюри смотрит, что Postgres живая, а не что пароль уникальный.

Схема и данные создаются **один раз**, когда том/каталог данных пустой:

1. `backend/sql/init.sql` — `travel_cards`, `user_swipes`
2. `backend/sql/mock_data.sql` — 5 карточек Ольги
3. `backend/sql/02b-local-photos.sql` — локальные фото вместо Unsplash
4. `backend/sql/03-app_extras.sql` — сохранённое, брони, уникальный индекс свайпов
5. `backend/sql/04-extra-cards.sql` — ещё 12 карточек, чтобы колода не кончалась после пяти свайпов

Если SQL меняли, а база уже была создана — init-скрипты **не выполнятся снова**. Нужен сброс тома (см. §8).

---

## 4. Файл `.env` и токены

В корне проекта:

```powershell
copy .env.example .env
```

`.env` в git **не коммитится**. Пример — `.env.example`.

### Что обязательно

Для стабильного демо **обязательна только база** (`DATABASE_URL` / значения compose). Без неё API не стартует.

### Что не обязательно, но усиливает демо

| Переменная | Зачем | Откуда взять |
|---|---|---|
| `TELEGRAM_BOT_TOKEN` | Проверка подписи `Telegram.WebApp.initData` на сервере | [@BotFather](https://t.me/BotFather) после `/newbot` |
| `TELEGRAM_REQUIRE_INITDATA=true` | Запретить гостей без подписи Telegram | сами ставите, только для «боевого» Mini App |
| `OPENAI_API_KEY` или `OSTROVOK_LLM_API_KEY` | Живые ответы модели в чате | кабинет OpenAI / совместимый шлюз. **Не выдумывать.** |
| `OSTROVOK_LLM_BASE_URL` | Если не OpenAI, а YandexGPT / локальный шлюз | URL провайдера, по умолчанию `https://api.openai.com/v1` |
| `OSTROVOK_LLM_MODEL` | Имя модели | например `gpt-4o-mini` |

Без Telegram-токена **браузер на компьютере работает** (гость `guest-…`).  
Без ключа LLM помощник **всё равно ищет по Postgres** (город, бюджет, карточки). Для защиты этого достаточно.

Токен бота **не кладут в код и не публикуют** в README. Только `.env` или переменные среды.

Порты, если заняты:

```text
OSTROVOK_API_PORT=8080
OSTROVOK_POSTGRES_PORT=5432
```

---

## 5. Запуск для жюри — Docker Compose (предпочтительный)

В корне репозитория:

```powershell
cd путь\к\Ostrovok
copy .env.example .env
docker compose up --build
```

Первый раз качает образы `postgres:15`, `redis:7-alpine` и собирает API — несколько минут. Окно **не закрывать**.

Готово, когда в логе API есть `store: postgresql` и `ostrovok api on :8080`.

Откройте:

- приложение: http://127.0.0.1:8080/
- здоровье: http://127.0.0.1:8080/health

Ожидаемый JSON:

```json
{"status":"ok","service":"ostrovok-api","store":"postgresql"}
```

Фон (после проверки, что всё поднимается):

```powershell
docker compose up --build -d
docker compose logs -f api
```

Остановка:

```powershell
docker compose down
```

База при `down` **сохраняется** в томе `pgdata`. Свайпы жюри останутся до сброса тома.

---

## 6. Запуск для себя на Windows без Docker

Из корня проекта:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-local.ps1
```

Скрипт:

1. Если Docker есть — делает `docker compose up --build -d`.
2. Если Docker нет — поднимает PostgreSQL 15 в `%LOCALAPPDATA%\Ostrovok\pgsql` и данные в `%LOCALAPPDATA%\Ostrovok\pgdata`, накатывает SQL, запускает `go run ./cmd/api`.

Откройте http://127.0.0.1:8080/  
Остановка API: `Ctrl+C` в том окне.

База после Ctrl+C обычно **продолжает висеть** на `5432`. Это нормально: следующий запуск переиспользует её. Полностью остановить:

```powershell
& "$env:LOCALAPPDATA\Ostrovok\pgsql\bin\pg_ctl.exe" -D "$env:LOCALAPPDATA\Ostrovok\pgdata" stop
```

Проверка цепочки свайпа скриптом:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\e2e-api.ps1
```

Должно напечатать `E2E OK` и `store=postgresql`.

---

## 7. Что нажать на защите (2–3 минуты)

1. Открыть http://127.0.0.1:8080/ — карточка с **фото**, не сайт Unsplash.
2. Показать http://127.0.0.1:8080/health — `"store":"postgresql"`.
3. Свайп вправо (♥). Статус: «Свайп учтён». Вкладка **Сохранено** — это место с сервера.
4. Следующая карточка **другая**, в блоке «Почему тебе подойдёт» есть PostgreSQL / теги лайков.
5. Ещё 1–2 свайпа в разные стороны — колода не пустеет сразу (17 карточек).
6. **AI-помощник** → «Хочу море до 10000» — ответ и кнопки вариантов из каталога.
7. По желанию: Telegram по HTTPS (следующий раздел).

Авторизация и оплата в MVP **намеренно выключены**.

---

## 8. Стабильность: чтобы не упало в момент демо

Сделайте это **вечером до защиты**, не за минуту до выхода.

1. **Дождитесь Docker** (или прогоните `run-local.ps1` заранее). Первый `compose up --build` долгий.
2. **Не закрывайте** Docker Desktop / окно API. Спящий режим ноутбука иногда рвёт контейнеры — разбудили, проверьте `/health`.
3. **Порты.** Если `8080` или `5432` заняты, в `.env`:
   ```
   OSTROVOK_API_PORT=8081
   OSTROVOK_POSTGRES_PORT=5433
   ```
   Тогда API: http://127.0.0.1:8081/ и `DATABASE_URL` с портом `5433`, если запускаете Go с хоста.
4. **SQL не подхватился.** Init выполняется только на **пустом** томе. После правок SQL:
   ```powershell
   docker compose down -v
   docker compose up --build
   ```
   `-v` стирает карточки и свайпы — это нормально перед чистым демо.
5. **Кириллица в пути** `D:\Разработка\…` ломает Flutter-шейдеры и `initdb`. Docker этот путь переносит. Локальный Postgres специально живёт в `%LOCALAPPDATA%\Ostrovok`.
6. **Не включайте** `OSTROVOK_ALLOW_MEMORY=true` на защите.
7. **Фото.** Должны открываться так: http://127.0.0.1:8080/static/places/ht-florence.jpg  
   Если 404 — API запущен не из `backend/` / образ собран без `static`.
8. **Перезапуск API** не обязан сбрасывать базу. Свайпы остаются в Postgres — это плюс для демо «рекомендации помнят».
9. **Сеть жюри.** `127.0.0.1` виден только на вашем ноутбуке. Телефон жюри — только через Telegram HTTPS или `http://ВАШ_LAN_IP:8080/` в одной Wi‑Fi (файрвол Windows может закрыть порт).
10. **Redis можно игнорировать**, если свайпы и health уже зелёные.

Полезные команды, если «ничего не открывается»:

```powershell
docker compose ps
docker compose logs api --tail 80
docker compose logs postgres_db --tail 40
Invoke-RestMethod http://127.0.0.1:8080/health
```

Юнит-тесты без Docker (не заменяют live-проверку):

```powershell
cd backend
go test ./...
```

---

## 9. Telegram Mini App (телефон жюри)

Telegram **не откроет** `http://127.0.0.1`. Нужен HTTPS.

1. API уже работает на `:8080`, `/health` = postgresql.
2. Туннель:

```powershell
winget install --id Cloudflare.cloudflared -e
powershell -ExecutionPolicy Bypass -File .\scripts\run-telegram.ps1
```

В логе будет `https://….trycloudflare.com`. Пока крутится этот процесс и ваш компьютер в сети — ссылка жива.

3. [@BotFather](https://t.me/BotFather):
   - `/newbot` — имя, username, **сохраните токен**.
   - `/newapp` — Web App URL = `https://….trycloudflare.com/` (корень, со слэшем).
4. На машине, где крутится API, в `.env` или в сессии:

```powershell
$env:TELEGRAM_BOT_TOKEN="токен_от_BotFather"
```

Для Docker перезапустите compose после правки `.env`:

```powershell
docker compose up -d --force-recreate api
```

5. Откройте бота в Telegram → Mini App. Гость будет `tg-<id>`, свайпы пишутся в ту же Postgres.

Выключили туннель или ноутбук — у жюри страница умрёт. На защите лучше **один ноутбук, туннель заранее, ссылка в заметке**.

Локальный браузер без токена бота по-прежнему работает.

Жёсткий режим (только подписанный Telegram, браузер без initData получит 401):

```
TELEGRAM_REQUIRE_INITDATA=true
```

На защите это включать только если точно открываете из Telegram.

---

## 10. Живая языковая модель (не обязательно)

Без ключа агент:

- понимает «подобрать / забронировать / менеджер»;
- вытаскивает город и бюджет;
- ищет в Postgres.

Этого хватает. Если есть **свой** ключ:

```powershell
$env:OPENAI_API_KEY="sk-..."
$env:OSTROVOK_LLM_MODEL="gpt-4o-mini"
```

Не вставляйте случайную строку «чтобы было» — запросы будут падать, чат станет хуже, чем без ключа.

---

## 11. Flutter (если спросят про «приложение», не про Mini App)

Терминал 1: Docker или `run-local.ps1` (API + Postgres).  
Терминал 2:

```powershell
.\scripts\run-mobile.ps1
```

На Windows из-за кириллицы в пути скрипт монтирует диск `Z:`. Подробности: [FLUTTER.md](FLUTTER.md), [TESTING.md](TESTING.md).

---

## 12. Чеклист за 10 минут до выхода к жюри

- [ ] `docker compose ps` — `postgres_db` healthy, `api` running **или** `run-local.ps1` без ошибок
- [ ] http://127.0.0.1:8080/health → `"store":"postgresql"`
- [ ] http://127.0.0.1:8080/ открывается, на карточке фото
- [ ] Свайп вправо → сохранённое и новая карточка
- [ ] `.\scripts\e2e-api.ps1` печатает `E2E OK`
- [ ] Ноутбук на зарядке, сон отключён на час
- [ ] Если обещали Telegram — туннель уже запущен, ссылка бота проверена с телефона
- [ ] Memory-режим не включён
- [ ] Ключи LLM/Telegram не светятся на слайде

Если всё это зелёное — сервис для защиты стабилен.
