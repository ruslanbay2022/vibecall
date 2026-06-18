# VibeCall

Кроссплатформенный аналог Skype: 1‑на‑1 аудио/видео-звонки, текстовый чат, демонстрация экрана. Web → Android → Desktop → iOS.

Стек: Flutter + Supabase (Auth/DB/Realtime/Storage/Edge Functions) + self-hosted LiveKit. Бюджет на старте — $0 (кроме VPS ~500–900 ₽/мес).

Полный план реализации: [PLAN.md](PLAN.md)

---

## Quick start — локальная разработка

### Prerequisites

- Flutter ≥3.32 / Dart ≥3.8 — https://docs.flutter.dev/get-started/install
- Supabase-проект (URL + anon key из Dashboard → Settings → API)
- Docker Desktop — для `supabase start` (локальный Postgres/Auth/Realtime)

### Запуск Web

```powershell
# 1. Клонировать и установить зависимости
git clone https://github.com/ruslanbay2022/vibecall.git
cd vibecall/client
flutter pub get

# 2. Настроить env
Copy-Item .env.example .env
# Заполнить SUPABASE_URL, SUPABASE_ANON_KEY, ENV=dev

# 3. Codegen (riverpod + freezed)
dart run build_runner build

# 4. Запустить
flutter run -d chrome --dart-define-from-file=.env
```

### Запуск Android

```powershell
# .env с ENV=prod для prod Supabase (или dev для локального)
flutter run --dart-define-from-file=.env
```

### Dev LiveKit (опционально)

Локальный LiveKit + Cloudflare Tunnel — см. [infra/dev/README.md](infra/dev/README.md).

### Дополнительные тулчейны

- **Supabase CLI** — `supabase start` / migrations; без scoop/winget можно положить бинарь в `.tools/` (gitignored) — см. [PLAN.md](PLAN.md) Phase 0
- **Docker Desktop** — для `supabase start` и dev LiveKit

---

## Production URLs

| Сервис | URL / где |
|--------|-----------|
| **Web** | https://vibecall-d85.pages.dev |
| **LiveKit** | `wss://vibecall.duckdns.org` |
| **Supabase** | Dashboard project `olnbzcozwwcvuqhyikqp` |
| **Android APK** | [GitHub Releases](https://github.com/ruslanbay2022/vibecall/releases) — latest `v0.1.3` |
| **VDS runbook** | [infra/prod/README.md](infra/prod/README.md) |
| **CF Pages** | [infra/pages/README.md](infra/pages/README.md) |

---

## Troubleshooting

| Проблема | Решение |
|----------|---------|
| `SUPABASE_URL is empty` | `--dart-define-from-file=.env` или APK из Releases |
| Web sign-in fail | Supabase Auth: Site URL + Redirect URLs = Pages URL (без trailing slash) |
| WSS / звонок timeout | Prod Edge secrets `LIVEKIT_*`; HTTPS на VDS; UFW 443/7881; VPN добавляет latency |
| ICE / NAT (no media) | UFW на VDS (§6.4); HTTPS/WSS только; при жёстком NAT — TURN (не настроен в MVP) |
| Обрыв связи при звонке | #96 — graceful end; не должно быть raw Error / бесконечного «Подключение…» |
| Нет ringback у звонящего | #95/#96 — ringback до ответа; на Android mic откладывается до answer |
| Белый кадр видео (Android) | #93 — Impeller отключён в `AndroidManifest.xml` |
| Камера toggle ломает видео | #93 — symmetric `setCameraEnabled`, не unpublish/republish |
| Echo на desktop | Наушники; mute проверка |
| Android mic/camera | Разрешения в Settings; dialog при звонке (#92) |
| Android screen off | Wakelock (#92); MIUI → «Без ограничений» |
| CF build fail | Root = repo root; output `client/build/web`; build cmd `infra/pages/build.sh` |
| `flutter run` Android | `ENV=prod` в `.env` для prod Supabase |
| Screen share Web prod | deferred — известный баг |
| VPN / высокая latency | `RoomOptions` tuned в `call_controller.dart` (adaptiveStream, 540p) |

---

## Releases

### Desktop (Linux + Windows)

Tag `v*` → `desktop_release.yml` → zip в GitHub Releases.

### Android

Tag `v*` → `android_release.yml` → signed APK (`vibecall-android-vX.Y.Z.apk`).

Keystore в GH Secrets — см. [infra/prod/README.md §11](infra/prod/README.md).

### Текущий prod tag

**`v0.1.3`** (`4bf26a6`, #97)

---

## Статус

**Phase 6 Production — закрыта**

| Фаза | Статус |
|------|--------|
| Phase 0 — Foundation | ✅ закрыта |
| Phase 1 — Supabase + Auth | ✅ закрыта |
| Phase 2 — Contacts | ✅ закрыта |
| Phase 3 — Calls | ✅ закрыта |
| Phase 4 — Chat | ✅ закрыта |
| Phase 5 — Screen share + Desktop release | ✅ закрыта |
| Phase 6 — Production (VDS, DuckDNS, UFW, CF Pages, Android APK) | ✅ **закрыта** |

Полная история шагов: [PLAN.md](PLAN.md)

### Deferred / future

- Screen share prod web — баг, fix позже
- Play Store / AAB — out of scope
- iOS — требует $99/год Apple Dev
- E2EE (LiveKit поддерживает) — Phase 7
- Запись звонков (LiveKit Egress) — Phase 7

---

## Лицензия

MIT — см. [LICENSE](LICENSE).
