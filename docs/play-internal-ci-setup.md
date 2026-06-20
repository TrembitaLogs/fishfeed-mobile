# CI → Google Play Internal Testing — setup checklist

Автоматична доставка підписаного `.aab` у трек **Internal testing** через
`.github/workflows/play-internal.yml`. Цей документ описує **разову** консольну
підготовку (її робить людина — CI її виконати не може) і як запускати доставку.

App identity:

| | |
|---|---|
| Package | `com.fishfeed.fishfeed` |
| Play developer ID | `8521468320594384180` |
| Play app ID | `4974924164036359588` |
| Firebase / GCP (Play API host) | `fishfeed-490510` |

> Останній залитий білд — **versionName 1.0.19 / versionCode 11**. Тобто умова
> «перший аплоад має бути ручним» (див. нижче) **вже виконана** — API прийматиме
> завантаження для цього застосунку.

---

## 1. Увімкнути Play Android Developer API

GCP Console → проєкт **`fishfeed-490510`** → **APIs & Services → Library** →
увімкнути **Google Play Android Developer API** (`androidpublisher.googleapis.com`).
(Імовірно вже увімкнено — його використовує RevenueCat-інтеграція.)

## 2. Service Account з правом релізу в тестові треки

Потрібен SA з дозволом заливати білди в треки. Наявний
`revenuecat@fishfeed-490510.iam.gserviceaccount.com` має лише фінансові права /
права на замовлення — для аплоаду їх **недостатньо**. Два варіанти:

- **(Рекомендовано) Окремий least-privilege SA для CI.** GCP Console → IAM &
  Admin → Service Accounts → Create → напр. `play-ci-uploader` → **Create key →
  JSON** → завантажити файл ключа.
- Або переввикористати наявний SA, додавши йому права з кроку 3.

## 3. Видати SA доступ у Play Console

Play Console → **Users and permissions** → **Invite new user** → вставити email
service account → на рівні **App** (`FishFeed`) увімкнути рівно два дозволи:

- ☑️ **Release apps to testing tracks** (Releases)
- ☑️ **View app information (read-only)**

> Альтернатива (раніший шлях) — Play Console → **Setup → API access** → link до
> GCP-проєкту. Новий рекомендований шлях — саме «Invite new user» вище.

⏳ **Propagation delay реальний:** після видачі прав доступ може поширюватись від
кількох хвилин до ~24 год. Якщо перший прогін падає з `401/403 The caller does
not have permission` — зачекати й перезапустити.

## 4. Додати GitHub-секрети

Repo **TrembitaLogs/fishfeed-mobile** → Settings → Secrets and variables →
Actions → New repository secret:

| Secret | Призначення | Статус |
|--------|-------------|--------|
| `PLAY_SERVICE_ACCOUNT_JSON` | Вміст JSON-ключа SA з кроку 2 (повний JSON, plaintext) | **додати** |
| `REVENUECAT_API_KEY_ANDROID` | Щоб у тест-білді працювали покупки | **додати** |
| `SENTRY_DSN` | Краш-репортинг у тест-білді | **додати** (опц.) |
| `POSTHOG_API_KEY` | Аналітика у тест-білді | **додати** (опц.) |
| `API_BASE_URL` | Прод-API | вже є (release.yml) |
| `KEYSTORE_BASE64` | Upload-keystore (base64) | вже є |
| `KEYSTORE_PASSWORD` / `KEY_PASSWORD` / `KEY_ALIAS` | Підпис | вже є |

> Якщо опційний секрет не заданий — білд усе одно збереться, але відповідна
> фіча (покупки/аналітика/краші) буде неактивна. Відсутній
> `PLAY_SERVICE_ACCOUNT_JSON` або `KEYSTORE_*` — крок впаде (fail-fast), що
> правильно.

## 5. (Перевірка) Перший ручний аплоад

Google Play API **не вміє створювати** лістинг застосунку — пакет має вже
існувати, з хоча б одним білдом, залитим вручну. Для FishFeed це **вже
зроблено** (1.0.19+11). Для нового застосунку це довелось би зробити раз вручну.

---

## Як запускати доставку

Після кроків 1–4 — два способи (обидва гейтнуті `format → analyze → test`):

1. **Ручна кнопка:** Actions → **Play Internal Testing** → **Run workflow**.
   Поле `version_name` можна лишити порожнім (візьметься з останнього `v*`-тега)
   або вписати `X.Y.Z`.
2. **Тег:** `git tag v1.0.20+12 && git push origin v1.0.20+12`. Тег запускає і
   цей workflow (→ Play Internal), і наявний `release.yml` (→ APK на сервер) —
   це два різні канали, конфлікту немає.

### Як рахується версія

- **versionName** — `X.Y.Z` з тега (push) або з інпута / останнього тега (ручний запуск).
- **versionCode** — `11 + github.run_number` (перший білд = `12`, далі монотонно
  зростає). Завжди вищий за наявні `11`, ручний bump не потрібен.
- ⚠️ На push-тезі **`+N` з тега для Play versionCode НЕ використовується** (його
  бере лише APK-канал у `release.yml`). Для Play код завжди run-number-based —
  щоб лічильник був безколізійним. Тестери бачать лише `versionName`.

> **Тримай CI єдиним завантажувачем у Internal Testing.** Якщо колись заллєш
> вручну білд із кодом, вищим за CI-шний, — підніми `VERSION_CODE_BASE` у
> workflow, інакше наступний CI-аплоад колізіїться.

## Troubleshooting

| Помилка | Причина / фікс |
|---------|----------------|
| `Package not found` | Пакет не існує / SA не має доступу до цього застосунку. Перевірити package name і права з кроку 3. |
| `Track not found` | Трек не існує. `internal/alpha/beta/production` стандартні; кастомні треки треба створити в Console. |
| `401/403 caller does not have permission` | Права SA ще не поширились (до 24 год) — зачекати й перезапустити; перевірити крок 3. |
| `Version code N has already been used` | versionCode не вищий за наявний. Підняти `VERSION_CODE_BASE` (хтось залив вручну вище за CI). |
