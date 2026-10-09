# Flutter: Android и iOS из одной кодовой базы

Основное мобильное приложение теперь находится в `mobile`. Одна Dart/Flutter-кодовая база содержит интерфейс, онбординг, свайпы, рекомендации, чат и кабинет.

## Почему Flutter

- Android можно собирать и запускать на Windows.
- Тот же код собирается для iOS на Mac.
- Интерфейс одинаковый на обеих платформах.
- Go API и его алгоритм рекомендаций остаются общими.
- Приложение продолжает работать офлайн без API.

Ограничение Apple остаётся: финальная сборка iOS и публикация в App Store выполняются только на Mac с Xcode.

## Важно про путь проекта

Папка `D:\Разработка\Ostrovok` содержит кириллицу. Flutter на Windows из такого пути падает при компиляции шейдеров. Скрипты `scripts\run-mobile.ps1` и `scripts\check-mobile.ps1` автоматически делают `subst Z:` на корень проекта. Если запускаете Flutter вручную:

```powershell
subst Z: "D:\Разработка\Ostrovok"
cd Z:\mobile
flutter run
```

Снять диск: `subst Z: /D`.

## Что установить на Windows

1. [Android Studio](https://developer.android.com/studio) — обязательно для Android-эмулятора и APK.
2. Flutter SDK: можно системный с [официального сайта](https://docs.flutter.dev/get-started/install/windows/mobile) **в путь без кириллицы**, например `C:\flutter`, либо использовать уже скачанный `.tools\flutter`.
3. Git for Windows. В репозитории есть portable Git в `.tools\git`.

В Android Studio при первом запуске установите:

- Android SDK;
- Android SDK Platform;
- Android SDK Command-line Tools;
- Android SDK Build-Tools;
- Android Emulator.

Затем создайте виртуальное устройство:

```text
Android Studio → More Actions → Virtual Device Manager
→ Create Device → Pixel → актуальный стабильный Android image
```

## Проверка окружения

```powershell
flutter doctor
flutter doctor --android-licenses
flutter devices
```

На все Android-лицензии ответьте `y`.

## Запуск

Терминал 1 — Go API:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-backend.ps1
```

Терминал 2 — Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run-mobile.ps1
```

Если эмулятора ещё нет, сначала откройте Android Studio, установите SDK и создайте Pixel-устройство. Без Android SDK `flutter run` на этой машине не соберёт APK.

Android Emulator автоматически использует:

```text
http://10.0.2.2:8080
```

Если сервер не запущен, приложение перейдёт на встроенный каталог.

## Физический Android-телефон

1. Включите режим разработчика и USB debugging.
2. Подключите телефон к Windows и подтвердите доверие.
3. Телефон и компьютер должны быть в одной сети.
4. Узнайте IPv4 компьютера:

   ```powershell
   ipconfig
   ```

5. Разрешите входящие подключения к порту 8080 в Windows Firewall.
6. Запустите:

   ```powershell
   .\scripts\run-mobile.ps1 -ApiUrl "http://192.168.1.25:8080"
   ```

   Замените IP на адрес своего компьютера.

## Сборка APK

```powershell
cd mobile
flutter build apk --release --dart-define=OSTROVOK_API_URL=https://api.example.com
```

Файл:

```text
mobile\build\app\outputs\flutter-apk\app-release.apk
```

Для локального тестового API вместо `https://api.example.com` можно указать IP компьютера, но для production нужен HTTPS.

## Сборка Android App Bundle для Google Play

```powershell
cd mobile
flutter build appbundle --release --dart-define=OSTROVOK_API_URL=https://api.example.com
```

Файл:

```text
mobile\build\app\outputs\bundle\release\app-release.aab
```

Перед публикацией потребуется создать upload keystore и прописать signing config. Секреты keystore нельзя добавлять в Git.

## iOS на Mac

```bash
cd mobile
flutter pub get
open ios/Runner.xcworkspace
```

В Xcode выберите Team и уникальный Bundle Identifier, затем:

```bash
flutter run --dart-define=OSTROVOK_API_URL=http://127.0.0.1:8080
```

Для TestFlight:

```bash
flutter build ipa --release \
  --dart-define=OSTROVOK_API_URL=https://api.example.com
```

## Проверки

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\check-mobile.ps1
```

Скрипт выполняет:

- `dart format`;
- `flutter analyze`;
- `flutter test`.

## Адрес API

Приоритет настройки:

1. `--dart-define=OSTROVOK_API_URL=...`;
2. Android Emulator: `http://10.0.2.2:8080`;
3. iOS Simulator: `http://127.0.0.1:8080`.

Для production обязательно используйте HTTPS.

## Старый SwiftUI-клиент

Папка `ios/Ostrovok` сохранена как прототип и источник дизайна. Основным клиентом считается `mobile`; новые функции следует добавлять туда, чтобы Android и iOS не расходились.
