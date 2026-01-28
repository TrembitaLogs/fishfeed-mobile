# Задача 4.5: Інструкція з налаштування Google Sign-In

## Огляд

Код для Google Sign-In повністю реалізовано. Цей документ описує ручні кроки, необхідні для завершення конфігурації Firebase/Google Cloud.

## Передумови

- Доступ до [Firebase Console](https://console.firebase.google.com)
- Bundle ID: `com.fishfeed.fishfeed` (iOS)
- Package name: `com.fishfeed.fishfeed` (Android)

---

## Крок 1: Налаштування Firebase проекту

1. Перейти до [Firebase Console](https://console.firebase.google.com)
2. Створити новий проект або вибрати існуючий
3. Перейти до **Authentication** > **Sign-in method**
4. Увімкнути провайдер **Google**
5. Налаштувати OAuth consent screen, якщо буде запропоновано

---

## Крок 2: Додати iOS додаток

1. У Firebase Console натиснути **Add app** > **iOS**
2. Ввести Bundle ID: `com.fishfeed.fishfeed`
3. Завантажити `GoogleService-Info.plist`
4. **Додати до Xcode проекту:**
   - Відкрити `ios/Runner.xcworkspace` в Xcode
   - Перетягнути `GoogleService-Info.plist` у Navigator (ліва панель) в папку Runner
   - У діалозі вибрати:
     - ✅ Copy items if needed
     - ✅ Add to targets: Runner
   - Натиснути Finish

> **Важливо:** Просто розмістити файл у папці недостатньо. Його потрібно додати через Xcode, щоб він був включений у bundle додатку.

### Оновити REVERSED_CLIENT_ID

1. Відкрити `GoogleService-Info.plist`
2. Знайти значення `REVERSED_CLIENT_ID` (формат: `com.googleusercontent.apps.XXXX-YYYY`)
3. Оновити в обох файлах:

**ios/Flutter/Debug.xcconfig:**
```
REVERSED_CLIENT_ID=com.googleusercontent.apps.ВАШ_РЕАЛЬНИЙ_CLIENT_ID
```

**ios/Flutter/Release.xcconfig:**
```
REVERSED_CLIENT_ID=com.googleusercontent.apps.ВАШ_РЕАЛЬНИЙ_CLIENT_ID
```

---

## Крок 3: Додати Android додаток

1. У Firebase Console натиснути **Add app** > **Android**
2. Ввести Package name: `com.fishfeed.fishfeed`
3. Додати SHA-1 fingerprint (для debug):
   ```bash
   cd android && ./gradlew signingReport
   ```
   Скопіювати значення SHA1 з виводу
4. Завантажити `google-services.json`
5. Розмістити файл у: `android/app/google-services.json`

---

## Крок 4: Перевірка налаштування

Запустити додаток і протестувати Google Sign-In:

```bash
# iOS (потрібен реальний пристрій, симулятор не підтримує Google Sign-In)
flutter run -d <device_id>

# Android
flutter run -d <device_id>
```

---

## Файли, змінені під час імплементації

| Файл | Опис |
|------|------|
| `pubspec.yaml` | Додано `google_sign_in: ^6.2.2` |
| `lib/services/auth/google_auth_service.dart` | Реалізація GoogleAuthService |
| `lib/services/auth/auth.dart` | Barrel файл |
| `lib/services/services.dart` | Оновлено експорти |
| `ios/Runner/Info.plist` | Додано CFBundleURLTypes |
| `ios/Flutter/Debug.xcconfig` | Додано placeholder REVERSED_CLIENT_ID |
| `ios/Flutter/Release.xcconfig` | Додано placeholder REVERSED_CLIENT_ID |
| `test/services/auth/google_auth_service_test.dart` | 26 unit тестів |

---

## Чекліст

- [ ] Firebase проект створено/вибрано
- [ ] Google Sign-In увімкнено в Authentication
- [ ] iOS додаток додано до Firebase
- [ ] `GoogleService-Info.plist` додано через Xcode в `ios/Runner/`
- [ ] `REVERSED_CLIENT_ID` оновлено в Debug.xcconfig
- [ ] `REVERSED_CLIENT_ID` оновлено в Release.xcconfig
- [ ] Android додаток додано до Firebase
- [ ] SHA-1 fingerprint додано
- [ ] `google-services.json` розміщено в `android/app/`
- [ ] Протестовано на реальному iOS пристрої
- [ ] Протестовано на Android пристрої/емуляторі
