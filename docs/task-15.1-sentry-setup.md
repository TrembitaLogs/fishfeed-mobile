# Задача 15.1: Інструкція з налаштування Sentry

## Огляд

Код для Sentry SDK повністю реалізовано. Цей документ описує архітектуру інтеграції та ручні кроки для налаштування Sentry проекту.

## Передумови

- Доступ до [Sentry Dashboard](https://sentry.io)
- Обліковий запис Sentry (безкоштовний план доступний)

---

## Крок 1: Створення проекту в Sentry

1. Перейти до [Sentry Dashboard](https://sentry.io)
2. Натиснути **Create Project**
3. Вибрати платформу: **Flutter**
4. Ввести назву проекту: `FishFeed`
5. Натиснути **Create Project**
6. Скопіювати **DSN** (формат: `https://xxx@xxx.ingest.sentry.io/xxx`)

---

## Крок 2: Додати DSN в .env

Відкрити файл `.env` і додати:

```env
# Error Tracking
SENTRY_DSN=https://your-public-key@your-org.ingest.sentry.io/your-project-id
```

> **Важливо:** DSN є публічним ключем і безпечний для включення в мобільний додаток.

---

## Архітектура інтеграції

### Ініціалізація

Sentry ініціалізується в `main.dart` до запуску додатка:

```dart
await SentryService.instance.initialize(
  appRunner: () async {
    // App initialization
    runApp(const ProviderScope(child: FishFeedApp()));
  },
);
```

Це дозволяє:
- Захоплювати помилки під час запуску
- Автоматично відстежувати crashes
- Встановлювати правильний environment

### Конфігурація

| Параметр | Development | Production |
|----------|-------------|------------|
| `tracesSampleRate` | 100% | 20% |
| `environment` | development | production |
| `debug` | true | false |
| `enableAutoSessionTracking` | true | true |
| `maxBreadcrumbs` | 100 | 100 |

---

## Компоненти

### 1. SentryService

Розташування: `lib/services/sentry/sentry_service.dart`

Singleton сервіс з методами:

| Метод | Опис |
|-------|------|
| `initialize()` | Ініціалізація SDK |
| `captureException()` | Захоплення помилки з контекстом |
| `captureMessage()` | Захоплення інформаційного повідомлення |
| `setUser()` | Встановлення user context |
| `clearUser()` | Очищення user context |
| `addBreadcrumb()` | Додавання breadcrumb |
| `setTag()` | Встановлення тегу |
| `setContext()` | Встановлення контексту |
| `startTransaction()` | Запуск performance transaction |

### 2. Navigation Observer

Розташування: `lib/presentation/router/app_router.dart`

`SentryNavigatorObserver` автоматично:
- Створює transactions для навігації
- Додає breadcrumbs при переході між екранами
- Відстежує час перебування на екранах

### 3. HTTP Tracing

Розташування: `lib/data/datasources/remote/api_client.dart`

`sentry_dio` інтерсептор автоматично:
- Відстежує HTTP запити як spans
- Захоплює failed requests
- Додає breadcrumbs для API calls

### 4. User Context Sync

Розташування: `lib/services/sentry/sentry_user_sync.dart`

Provider автоматично:
- Встановлює user context при логіні
- Очищує user context при логауті
- Оновлює контекст при зміні даних користувача

---

## Використання в коді

### Захоплення помилки

```dart
try {
  await riskyOperation();
} catch (e, stackTrace) {
  await SentryService.instance.captureException(
    e,
    stackTrace: stackTrace,
    message: 'Failed to perform risky operation',
    extras: {'operationType': 'riskyOperation'},
  );
}
```

### Додавання breadcrumb

```dart
await SentryService.instance.addBreadcrumb(
  message: 'User tapped feed button',
  category: 'ui.tap',
  data: {'fishId': fish.id},
);
```

### Performance tracing

```dart
final transaction = SentryService.instance.startTransaction(
  name: 'loadFishData',
  operation: 'db.query',
);

try {
  await loadData();
  transaction?.status = SpanStatus.ok();
} catch (e) {
  transaction?.status = SpanStatus.internalError();
} finally {
  await transaction?.finish();
}
```

---

## Файли, змінені під час імплементації

| Файл | Опис |
|------|------|
| `pubspec.yaml` | Додано `sentry_flutter: ^8.9.0`, `sentry_dio: ^8.9.0` |
| `lib/services/sentry/sentry_service.dart` | Реалізація SentryService |
| `lib/services/sentry/sentry_user_sync.dart` | Синхронізація user context |
| `lib/services/sentry/sentry.dart` | Barrel файл |
| `lib/services/services.dart` | Оновлено експорти |
| `lib/main.dart` | Ініціалізація Sentry |
| `lib/app.dart` | Додано SentryUserSyncListener |
| `lib/presentation/router/app_router.dart` | Додано SentryNavigatorObserver |
| `lib/data/datasources/remote/api_client.dart` | Додано Sentry Dio interceptor |
| `test/services/sentry/sentry_service_test.dart` | Unit тести |

---

## Тестування

### Примусовий crash

Для тестування інтеграції можна викликати примусовий crash:

```dart
// Тільки для тестування!
throw Exception('Test crash for Sentry');
```

### Перевірка в Sentry Dashboard

1. Перейти до Sentry Dashboard
2. Вибрати проект FishFeed
3. Перевірити секції:
   - **Issues** - захоплені помилки
   - **Performance** - HTTP та navigation traces
   - **Releases** - версії додатка

---

## Чекліст

### Sentry Dashboard
- [ ] Проект створено
- [ ] DSN скопійовано
- [ ] Alert rules налаштовано (опціонально)
- [ ] Team members додано (опціонально)

### Код
- [ ] DSN додано в `.env`
- [ ] Тестовий crash перевірено в dashboard
- [ ] Navigation traces відображаються
- [ ] HTTP requests відстежуються

---

## Корисні посилання

- [Sentry Flutter Documentation](https://docs.sentry.io/platforms/flutter/)
- [Sentry Dio Integration](https://docs.sentry.io/platforms/flutter/integrations/dio/)
- [Sentry Performance Monitoring](https://docs.sentry.io/platforms/flutter/performance/)
- [Sentry Pricing](https://sentry.io/pricing/)
