# Налаштування Push-нотифікацій для iOS (APNs + Firebase)

Цей посібник описує ручні кроки налаштування push-нотифікацій для iOS.

## Передумови

- Apple Developer Account (потрібна платна підписка)
- Створений Firebase проект
- Встановлений Xcode

## Крок 1: Налаштування Firebase проекту

### 1.1 Додавання iOS додатку до Firebase

1. Перейдіть до [Firebase Console](https://console.firebase.google.com/)
2. Виберіть ваш проект (або створіть новий)
3. Натисніть "Add app" та виберіть iOS
4. Введіть Bundle ID: `com.fishfeed.mobile`
5. Завантажте `GoogleService-Info.plist`

### 1.2 Додавання GoogleService-Info.plist до проекту

1. Скопіюйте завантажений `GoogleService-Info.plist` до:
   ```
   ios/Runner/GoogleService-Info.plist
   ```

2. Відкрийте Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. В Xcode клікніть правою кнопкою на папці `Runner` -> "Add Files to Runner..."
4. Виберіть `GoogleService-Info.plist`
5. Переконайтесь, що "Copy items if needed" відмічено
6. Натисніть "Add"

## Крок 2: Створення APNs Authentication Key

### 2.1 Генерація APNs ключа в Apple Developer Portal

1. Перейдіть до [Apple Developer Portal](https://developer.apple.com/account/)
2. Перейдіть до "Certificates, Identifiers & Profiles"
3. Виберіть "Keys" у бічній панелі
4. Натисніть кнопку "+" для створення нового ключа
5. Введіть назву ключа (напр., "FishFeed APNs Key")
6. Відмітьте "Apple Push Notifications service (APNs)"
7. Натисніть "Continue", потім "Register"
8. **Важливо**: Завантажте `.p8` файл одразу (його можна завантажити лише один раз!)
9. Запишіть **Key ID**, що відображається на сторінці
10. Запишіть ваш **Team ID** (видно у верхньому правому куті або в розділі Membership)

### 2.2 Завантаження APNs ключа до Firebase

1. Перейдіть до [Firebase Console](https://console.firebase.google.com/)
2. Виберіть ваш проект
3. Перейдіть до Project Settings (іконка шестерні)
4. Виберіть вкладку "Cloud Messaging"
5. У розділі "Apple app configuration" натисніть "Upload" біля APNs Authentication Key
6. Завантажте ваш `.p8` файл
7. Введіть **Key ID** з Apple Developer Portal
8. Введіть ваш **Team ID**
9. Натисніть "Upload"

## Крок 3: Увімкнення Push Notifications в Xcode

### 3.1 Додавання Push Notifications Capability

1. Відкрийте Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Виберіть проект `Runner` у навігаторі
3. Виберіть таргет `Runner`
4. Перейдіть на вкладку "Signing & Capabilities"
5. Натисніть "+ Capability"
6. Знайдіть та додайте "Push Notifications"

### 3.2 Перевірка Background Modes

Переконайтесь, що "Background Modes" capability додано з:
- Remote notifications (має бути вже налаштовано)

## Крок 4: Перевірка конфігурації

### 4.1 Перевірка Entitlements

Файл `Runner.entitlements` має містити:
```xml
<key>aps-environment</key>
<string>development</string>
```

Для production Xcode автоматично використає `production` при архівуванні.

### 4.2 Перевірка Info.plist

Файл `Info.plist` має містити:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## Крок 5: Встановлення CocoaPods залежностей

Після додавання `GoogleService-Info.plist` виконайте:

```bash
cd ios
pod install --repo-update
cd ..
```

## Крок 6: Тестування

### Важливі примітки

- Push-нотифікації **не працюють** на iOS Simulator
- Потрібно тестувати на **реальному iOS пристрої**
- Переконайтесь, що ваш пристрій зареєстрований в Apple Developer Portal для development тестування

### Чек-лист тестування

1. Зберіть та запустіть на фізичному iOS пристрої
2. Прийміть дозвіл на нотифікації коли з'явиться запит
3. Перевірте, що FCM токен отримано (перегляньте debug консоль)
4. Надішліть тестову нотифікацію з Firebase Console:
   - Перейдіть до Firebase Console -> Cloud Messaging
   - Натисніть "Send your first message"
   - Введіть заголовок та текст
   - Виберіть ваш iOS додаток як ціль
   - Надішліть нотифікацію

## Вирішення проблем

### FCM токен не отримується

- Переконайтесь, що `GoogleService-Info.plist` правильно додано до проекту
- Перевірте, що APNs ключ завантажено до Firebase
- Перевірте, що Push Notifications capability увімкнено
- Переконайтесь, що тестуєте на реальному пристрої

### Нотифікації не з'являються

- Перевірте, що дозвіл на нотифікації надано
- Перевірте конфігурацію APNs в Firebase Console
- Перевірте підключення пристрою до інтернету
- Перегляньте консоль Xcode на наявність помилок

### Помилки збірки

Якщо бачите помилки імпорту Firebase:
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
flutter clean
flutter pub get
```

## Production реліз

Перед випуском в App Store:

1. Переконайтесь, що `aps-environment` буде встановлено в `production` (Xcode робить це автоматично при архівуванні)
2. Протестуйте push-нотифікації в TestFlight перед фінальним релізом
3. Перевірте правильність всіх конфігурацій Firebase та APNs

## Розташування файлів

| Файл | Шлях | Статус |
|------|------|--------|
| GoogleService-Info.plist | `ios/Runner/GoogleService-Info.plist` | **Потрібно додати** |
| Runner.entitlements | `ios/Runner/Runner.entitlements` | Налаштовано |
| AppDelegate.swift | `ios/Runner/AppDelegate.swift` | Налаштовано |
| Info.plist | `ios/Runner/Info.plist` | Налаштовано |
