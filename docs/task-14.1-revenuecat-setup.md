# Задача 14.1: Інструкція з налаштування RevenueCat SDK

## Огляд

Код для RevenueCat SDK повністю реалізовано. Цей документ описує ручні кроки, необхідні для завершення конфігурації RevenueCat, App Store Connect та Google Play Console.

## Передумови

- Доступ до [RevenueCat Dashboard](https://app.revenuecat.com)
- Доступ до [App Store Connect](https://appstoreconnect.apple.com)
- Доступ до [Google Play Console](https://play.google.com/console)
- Bundle ID: `com.fishfeed.fishfeed` (iOS)
- Package name: `com.fishfeed.fishfeed` (Android)

---

## Крок 1: Створення проекту в RevenueCat

1. Перейти до [RevenueCat Dashboard](https://app.revenuecat.com)
2. Натиснути **Create new project**
3. Ввести назву проекту: `FishFeed`
4. Натиснути **Create project**

---

## Крок 2: Додати iOS додаток

1. У проекті натиснути **+ New** > **App**
2. Вибрати **App Store (iOS / macOS)**
3. Ввести:
   - App name: `FishFeed iOS`
   - Bundle ID: `com.fishfeed.fishfeed`
4. Натиснути **Save changes**
5. Скопіювати **Public SDK Key** (формат: `appl_xxxxxxxxx`)

### Налаштування App Store Connect

1. Перейти до [App Store Connect](https://appstoreconnect.apple.com)
2. Вибрати додаток FishFeed
3. Перейти до **App Information** > **App Store Server Notifications**
4. Додати RevenueCat Production URL:
   ```
   https://api.revenuecat.com/v1/subscribers/[APP_ID]/notifications/apple
   ```
5. У RevenueCat Dashboard:
   - Перейти до iOS App > **App Store Connect API**
   - Завантажити App Store Connect API Key (.p8 файл)
   - Або налаштувати Shared Secret

---

## Крок 3: Додати Android додаток

1. У проекті RevenueCat натиснути **+ New** > **App**
2. Вибрати **Play Store (Android)**
3. Ввести:
   - App name: `FishFeed Android`
   - Package name: `com.fishfeed.fishfeed`
4. Натиснути **Save changes**
5. Скопіювати **Public SDK Key** (формат: `goog_xxxxxxxxx`)

### Налаштування Google Play Console

1. Перейти до [Google Play Console](https://play.google.com/console)
2. Перейти до **Setup** > **API access**
3. Створити Service Account з правами на Billing
4. Завантажити JSON credentials
5. У RevenueCat Dashboard:
   - Перейти до Android App > **Service credentials**
   - Завантажити JSON credentials file

---

## Крок 4: Створення продуктів в App Store Connect

1. Перейти до **Monetization** > **Subscriptions**
2. Створити Subscription Group: `FishFeed Premium`
3. Додати підписки:

| Product ID | Назва | Ціна | Період |
|------------|-------|------|--------|
| `premium_monthly` | Premium Monthly | $3.99 | 1 місяць |
| `premium_annual` | Premium Annual | $29.99 | 1 рік |

4. Перейти до **Monetization** > **In-App Purchases**
5. Додати Non-Consumable:

| Product ID | Назва | Ціна |
|------------|-------|------|
| `remove_ads_forever` | Remove Ads Forever | $3.99 |

---

## Крок 5: Створення продуктів в Google Play Console

1. Перейти до **Monetize** > **Subscriptions**
2. Створити підписки:

| Product ID | Base plan ID | Ціна | Період |
|------------|--------------|------|--------|
| `premium_monthly` | `monthly` | $3.99 | 1 місяць |
| `premium_annual` | `annual` | $29.99 | 1 рік |

3. Перейти до **Monetize** > **In-app products**
4. Додати One-time product:

| Product ID | Назва | Ціна |
|------------|-------|------|
| `remove_ads_forever` | Remove Ads Forever | $3.99 |

---

## Крок 6: Налаштування Offerings в RevenueCat

1. У RevenueCat Dashboard перейти до **Products**
2. Імпортувати продукти з App Store Connect та Google Play
3. Перейти до **Offerings**
4. Створити Offering: `default`
5. Додати Packages:
   - `$rc_monthly` → `premium_monthly`
   - `$rc_annual` → `premium_annual`
6. Створити Offering: `remove_ads`
7. Додати Package:
   - `lifetime` → `remove_ads_forever`

---

## Крок 7: Додати API ключі в .env

Відкрити файл `.env` і додати ключі:

```env
# RevenueCat Configuration
REVENUECAT_API_KEY_IOS=appl_xxxxxxxxxxxxxxxxxx
REVENUECAT_API_KEY_ANDROID=goog_xxxxxxxxxxxxxxxxxx
```

> **Важливо:** Використовуйте **Public SDK Key** (не Secret API Key). Public key безпечний для включення в мобільний додаток.

---

## Крок 8: Налаштування Entitlements

1. У RevenueCat Dashboard перейти до **Entitlements**
2. Створити Entitlement: `premium`
3. Прив'язати продукти:
   - `premium_monthly`
   - `premium_annual`
4. Створити Entitlement: `no_ads`
5. Прив'язати продукти:
   - `premium_monthly`
   - `premium_annual`
   - `remove_ads_forever`

---

## Крок 9: Тестування

### Sandbox тестування (iOS)

1. У App Store Connect створити Sandbox Tester:
   - **Users and Access** > **Sandbox** > **Testers**
2. На iOS пристрої:
   - **Settings** > **App Store** > **Sandbox Account**
   - Увійти з Sandbox Tester email

### Тестування (Android)

1. У Google Play Console додати Test users:
   - **Testing** > **Internal testing** > **Testers**
2. Опублікувати internal track build

### Перевірка в додатку

```bash
# Запустити в debug mode - логи RevenueCat будуть видимі
flutter run
```

Очікувані логи при успішній ініціалізації:
```
PurchaseService: Initialized successfully
```

---

## Файли, змінені під час імплементації

| Файл | Опис |
|------|------|
| `pubspec.yaml` | Додано `purchases_flutter: ^8.0.0` |
| `.env.example` | Додано `REVENUECAT_API_KEY_IOS`, `REVENUECAT_API_KEY_ANDROID` |
| `lib/services/purchase/purchase_service.dart` | Реалізація PurchaseService |
| `lib/services/purchase/purchase.dart` | Barrel файл |
| `lib/services/services.dart` | Оновлено експорти |
| `lib/main.dart` | Додано ініціалізацію PurchaseService |
| `test/services/purchase/purchase_service_test.dart` | Unit тести |

---

## Чекліст

### RevenueCat Dashboard
- [ ] Проект створено
- [ ] iOS додаток додано
- [ ] Android додаток додано
- [ ] Entitlements налаштовано (`premium`, `no_ads`)
- [ ] Offerings налаштовано (`default`, `remove_ads`)

### App Store Connect
- [ ] Subscription Group створено
- [ ] `premium_monthly` підписка створена
- [ ] `premium_annual` підписка створена
- [ ] `remove_ads_forever` IAP створено
- [ ] Server Notifications URL налаштовано
- [ ] Sandbox Tester створено

### Google Play Console
- [ ] `premium_monthly` підписка створена
- [ ] `premium_annual` підписка створена
- [ ] `remove_ads_forever` продукт створено
- [ ] Service Account налаштовано
- [ ] Test users додано

### Код
- [ ] API ключі додано в `.env`
- [ ] Тестування на iOS sandbox
- [ ] Тестування на Android test track

---

## Корисні посилання

- [RevenueCat Documentation](https://docs.revenuecat.com)
- [RevenueCat Flutter SDK](https://docs.revenuecat.com/docs/flutter)
- [App Store Connect Subscriptions](https://developer.apple.com/app-store/subscriptions/)
- [Google Play Billing](https://developer.android.com/google/play/billing)
