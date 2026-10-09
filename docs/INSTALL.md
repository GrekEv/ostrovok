# Установка и запуск «Островка»

Проект состоит из трёх частей:

- `mobile` — основной клиент на Flutter для Android и iOS;
- `backend` — API на Go, запускается на Windows, macOS, Linux или в Docker;
- `ios/Ostrovok` — старый SwiftUI-прототип, собирается только на macOS с Xcode.

Для Android на Windows используйте [docs/FLUTTER.md](FLUTTER.md). Ниже — Go API и устаревший iOS-прототип.

Если API не запущен, приложение не ломается: оно автоматически использует встроенный каталог и локальные рекомендации.

## 1. Что скачать

### Обязательно для iOS

1. Mac с macOS, поддерживаемой актуальным Xcode.
2. [Xcode из App Store](https://apps.apple.com/app/xcode/id497799835).
3. Apple ID. Бесплатного аккаунта достаточно для симулятора и личного iPhone; TestFlight и App Store требуют платную программу Apple Developer.

### Для Go API — один из вариантов

- [Go](https://go.dev/dl/) версии 1.22 или новее;
- либо [Docker Desktop](https://www.docker.com/products/docker-desktop/).

На Windows Go можно установить командой:

```powershell
winget install --id GoLang.Go --exact
```

После установки закройте и заново откройте PowerShell.

На macOS:

```bash
brew install go
```

Если Homebrew отсутствует, установите Go с официального сайта.

## 2. Быстрый запуск API

### Вариант A — Docker

В корне проекта:

```bash
docker compose up --build
```

Поднимаются PostgreSQL 15 (`travel_cards`, `user_swipes` из репозитория Ольги), Redis и Go API. Схема: `backend/sql/init.sql`, данные: `backend/sql/mock_data.sql`.

Проверка:

```text
http://127.0.0.1:8080/health
```

В ответе должно быть `"store":"postgresql"`. Если меняли SQL, сбросьте том: `docker compose down -v`.

Остановка:

```bash
docker compose down
```

### Вариант B — Windows без Docker

В PowerShell из корня проекта:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-backend.ps1
```

Окно должно остаться открытым. Остановка — `Ctrl+C`.

Проверка кода и тестов:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check.ps1
```

### Вариант C — macOS

```bash
chmod +x scripts/*.sh
./scripts/run-backend.sh
```

Или напрямую:

```bash
cd backend
go test ./...
go run ./cmd/api
```

## 3. Запуск iOS в симуляторе

1. Сначала запустите Go API одним из способов выше.
2. Откройте `ios/Ostrovok/Ostrovok.xcodeproj` в Xcode. Можно командой:

   ```bash
   ./scripts/open-ios.sh
   ```

3. В верхней панели Xcode выберите схему `Ostrovok` и любой iPhone с iOS 17+.
4. Нажмите `Run` (`⌘R`).
5. При первом запуске пройдите онбординг или нажмите «Пропустить».
6. Во вкладке «Кабинет» проверьте статус:
   - `API подключён` — рекомендации идут через Go;
   - `Офлайн-режим` — приложение использует встроенный каталог.

Для симулятора адрес API по умолчанию:

```text
http://127.0.0.1:8080
```

## 4. Запуск на физическом iPhone

1. iPhone и Mac должны находиться в одной Wi‑Fi-сети.
2. Узнайте IP-адрес Mac:

   ```bash
   ipconfig getifaddr en0
   ```

3. В Xcode откройте `Product → Scheme → Edit Scheme… → Run → Arguments`.
4. В `Environment Variables` добавьте:

   ```text
   OSTROVOK_API_URL=http://IP_ВАШЕГО_MAC:8080
   ```

   Пример: `http://192.168.1.25:8080`.

5. Откройте target `Ostrovok → Signing & Capabilities`, выберите свой Team.
6. Подключите iPhone, подтвердите доверие и выберите его в списке устройств.
7. Нажмите `Run`.
8. Разрешите приложению доступ к локальной сети.

Если API не подключается:

- убедитесь, что сервер запущен;
- откройте порт `8080` в файрволе macOS;
- проверьте `http://IP_ВАШЕГО_MAC:8080/health` из Safari на iPhone;
- проверьте, что Wi‑Fi не изолирует устройства друг от друга.

## 5. Проверка API вручную

Здоровье сервиса:

```bash
curl http://127.0.0.1:8080/health
```

Каталог:

```bash
curl http://127.0.0.1:8080/v1/catalog
curl http://127.0.0.1:8080/v1/offers/ht-florence
```

Рекомендации:

```bash
curl -X POST http://127.0.0.1:8080/v1/recommendations \
  -H "Content-Type: application/json" \
  -d '{"countryCodes":["IT"],"priorityIDs":["city"],"skipped":false,"swipes":[]}'
```

Чат:

```bash
curl -X POST http://127.0.0.1:8080/v1/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Забронировать","guestId":"guest-demo","liked":[]}'
```

Бронь и очередь менеджера:

```bash
curl -X POST http://127.0.0.1:8080/v1/bookings \
  -H "Content-Type: application/json" \
  -d '{"guestId":"guest-demo","offerId":"ht-florence","kind":"delayed","dates":"июнь","note":"позже"}'
curl "http://127.0.0.1:8080/v1/bookings?guestId=guest-demo"
curl "http://127.0.0.1:8080/v1/manager/tickets?guestId=guest-demo"
```

В PowerShell вместо переноса `\` можно выполнить команду одной строкой.

## 6. Сброс тестовых данных

В приложении:

```text
Кабинет → Сбросить онбординг и свайпы
```

Данные хранятся локально в `UserDefaults`. Удаление приложения из симулятора также очищает их.

## 7. TestFlight и установка другим людям

Потребуются:

1. платный аккаунт [Apple Developer](https://developer.apple.com/programs/);
2. уникальный Bundle Identifier вместо тестового `ru.ostrovok.app`;
3. созданное приложение в App Store Connect;
4. иконка 1024×1024 и обязательные сведения о конфиденциальности.

В Xcode:

```text
Product → Archive → Distribute App → App Store Connect → Upload
```

После обработки сборки добавьте тестировщиков в TestFlight.

## 8. Что потребует внешних аккаунтов

Кодовая база подготовлена для дальнейшего подключения, но без ваших договоров и ключей нельзя включить:

- Sign in with Apple и Google Sign-In;
- реальные каталоги отелей, туров и авиабилетов;
- оплату и возвраты;
- LLM-провайдера для настоящего ИИ-диалога;
- push-уведомления;
- публикацию в TestFlight/App Store.

Не добавляйте секреты в Git. Храните их в переменных окружения или секретах CI.

## 9. Частые проблемы

### `go` не найден

Перезапустите терминал после установки и проверьте:

```bash
go version
```

### Порт 8080 занят

Для локального Go:

```powershell
$env:PORT="8081"
.\scripts\run-backend.ps1
```

Затем укажите в Xcode `OSTROVOK_API_URL=http://127.0.0.1:8081`.

Для Docker создайте `.env` из `.env.example` и измените `OSTROVOK_API_PORT`.

### Xcode не открывается на Windows

Это ограничение Apple. Исходники можно редактировать на Windows, но сборка и симулятор iOS доступны только на Mac.

### API выключен

Приложение продолжит работать локально. Ошибка и кнопка повторного подключения отображаются во вкладке «Кабинет».
