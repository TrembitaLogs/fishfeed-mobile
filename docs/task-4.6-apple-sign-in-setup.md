# Задача 4.6: Інструкція з налаштування Sign in with Apple

## Огляд

Код для Sign in with Apple повністю реалізовано. Цей документ описує ручні кроки, необхідні для завершення конфігурації в Apple Developer Portal.

## Передумови

- Обліковий запис [Apple Developer Program](https://developer.apple.com/programs/) ($99/рік)
- Bundle ID: `com.fishfeed.mobile` (iOS)
- Доступ до [Apple Developer Portal](https://developer.apple.com/account)

---

## Крок 1: Налаштування App ID в Apple Developer Portal

1. Перейти до [Apple Developer Portal](https://developer.apple.com/account)
2. Вибрати **Certificates, Identifiers & Profiles**
3. У бічному меню вибрати **Identifiers**
4. Знайти існуючий App ID (`com.fishfeed.mobile`) або створити новий:
   - Натиснути **+** для створення нового
   - Вибрати **App IDs** > **Continue**
   - Вибрати **App** > **Continue**
   - Заповнити:
     - Description: `FishFeed`
     - Bundle ID: `com.fishfeed.mobile` (Explicit)
5. У списку **Capabilities** знайти та увімкнути **Sign in with Apple**
6. Натиснути **Continue** > **Register**

---

## Крок 2: Створити Service ID (для web/backend)

> **Примітка:** Цей крок потрібен тільки якщо backend буде валідувати Apple токени.

1. В **Identifiers** натиснути **+**
2. Вибрати **Services IDs** > **Continue**
3. Заповнити:
   - Description: `FishFeed Service`
   - Identifier: `com.fishfeed.mobile.service`
4. Натиснути **Continue** > **Register**
5. Знайти створений Service ID у списку та натиснути на нього
6. Увімкнути **Sign in with Apple**
7. Натиснути **Configure**:
   - Primary App ID: вибрати `com.fishfeed.mobile`
   - Domains: додати домен вашого backend (наприклад, `api.fishfeed.com`)
   - Return URLs: додати callback URL backend (наприклад, `https://api.fishfeed.com/auth/apple/callback`)
8. Натиснути **Save** > **Continue** > **Save**

---

## Крок 3: Створити ключ для серверної валідації

> **Примітка:** Потрібно для backend валідації токенів.

1. У бічному меню вибрати **Keys**
2. Натиснути **+** для створення нового ключа
3. Заповнити:
   - Key Name: `FishFeed Sign in with Apple`
4. Увімкнути **Sign in with Apple**
5. Натиснути **Configure**:
   - Primary App ID: вибрати `com.fishfeed.mobile`
6. Натиснути **Save** > **Continue** > **Register**
7. **Важливо:** Завантажити `.p8` файл ключа та зберегти в безпечному місці
8. Записати **Key ID** - він знадобиться для backend

---

## Крок 4: Перевірка конфігурації Xcode

Проект вже налаштовано з entitlements. Перевірте:

1. Відкрити `ios/Runner.xcworkspace` в Xcode
2. Вибрати target **Runner**
3. Перейти до **Signing & Capabilities**
4. Переконатися що:
   - Team вибрано правильно
   - Bundle Identifier: `com.fishfeed.mobile`
   - **Sign in with Apple** capability присутній

Якщо capability відсутній:
1. Натиснути **+ Capability**
2. Знайти та додати **Sign in with Apple**

---

## Крок 5: Перевірка налаштування

Запустити додаток і протестувати Sign in with Apple:

```bash
# Потрібен реальний iOS пристрій (iOS 13+)
# Симулятор має обмежену підтримку Sign in with Apple
flutter run -d <device_id>
```

### Тестування на симуляторі

Sign in with Apple на симуляторі працює з обмеженнями:
- Потрібен Apple ID, увімкнений для двофакторної автентифікації
- Деякі функції можуть не працювати

Рекомендується тестувати на реальному пристрої.

---

## Особливості Apple Sign-In

### Перший логін vs наступні

Apple надає email та ім'я користувача **тільки при першому логіні**. Наш код автоматично зберігає цю інформацію локально для наступних сесій.

Якщо потрібно отримати ім'я знову:
1. Перейти до **Settings** > **Apple ID** > **Password & Security** > **Apps Using Apple ID**
2. Знайти FishFeed та натиснути **Stop Using Apple ID**
3. Наступний логін буде вважатися "першим"

### Private Relay Email

Користувач може вибрати "Hide My Email" при логіні. В такому випадку:
- Email буде у форматі: `xxxxx@privaterelay.appleid.com`
- Листи на цю адресу перенаправляються на реальний email користувача
- Для цього потрібно налаштувати домен у Service ID

---

## Файли, змінені під час імплементації

| Файл | Опис |
|------|------|
| `pubspec.yaml` | Додано `sign_in_with_apple: ^7.0.1` |
| `lib/services/auth/apple_auth_service.dart` | Реалізація AppleAuthService |
| `lib/core/services/secure_storage_service.dart` | Додано методи для Apple user info |
| `ios/Runner/Runner.entitlements` | Створено з Sign in with Apple capability |
| `ios/Runner.xcodeproj/project.pbxproj` | Додано CODE_SIGN_ENTITLEMENTS |
| `test/services/auth/apple_auth_service_test.dart` | 14 unit тестів |
| `test/core/services/secure_storage_service_test.dart` | 14 unit тестів |

---

## Інформація для Backend

Для валідації Apple токенів backend потребує:

| Параметр | Значення | Де знайти |
|----------|----------|-----------|
| Team ID | `XXXXXXXXXX` | Apple Developer Portal > Membership |
| Client ID | `com.fishfeed.mobile` | Bundle ID додатку |
| Key ID | `XXXXXXXXXX` | Keys section при створенні ключа |
| Private Key | `.p8` файл | Завантажується при створенні ключа |

### Приклад валідації токена (Node.js)

```javascript
const appleSignin = require('apple-signin-auth');

const clientSecret = appleSignin.getClientSecret({
  clientID: 'com.fishfeed.mobile',
  teamID: 'YOUR_TEAM_ID',
  keyID: 'YOUR_KEY_ID',
  privateKey: fs.readFileSync('path/to/AuthKey.p8'),
});

// Валідація identity token
const tokenResponse = await appleSignin.verifyIdToken(identityToken, {
  audience: 'com.fishfeed.mobile',
  ignoreExpiration: false,
});
```

---

## Чекліст

- [ ] Apple Developer Program membership активний
- [ ] App ID створено з Sign in with Apple capability
- [ ] Service ID створено (якщо потрібен backend)
- [ ] Ключ створено та `.p8` файл збережено
- [ ] Xcode проект має правильний Team та Bundle ID
- [ ] Sign in with Apple capability присутній в Xcode
- [ ] Протестовано на реальному iOS пристрої (iOS 13+)
- [ ] Backend налаштовано для валідації токенів (якщо потрібно)
