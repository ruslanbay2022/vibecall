# VibeCall

Кроссплатформенный аналог Skype: 1‑на‑1 аудио/видео-звонки, текстовый чат, демонстрация экрана. Web → Android → Desktop → iOS.!

Стек: Flutter + Supabase (Auth/DB/Realtime/Storage/Edge Functions) + self-hosted LiveKit. Бюджет на старте — $0.

## Документация

- Полный план реализации (для разработчиков и AI-агентов): [PLAN.md](PLAN.md)
- Архитектура, фазы, схемы БД, миграции, конфиги — там же.

## Локальный запуск

1. Установи Flutter ≥3.32 / Dart ≥3.8 (см. https://docs.flutter.dev/get-started/install).
2. Получи доступ к Supabase-проекту (URL и публичный ключ из Dashboard → Settings → API).
3. Скопируй шаблон env:
   ```powershell
   Copy-Item client/.env.example client/.env
   ```
4. Заполни `client/.env` реальными значениями (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). Файл уже в `.gitignore`, в репозиторий не попадёт.
5. Установи зависимости и запусти:
   ```powershell
   cd client
   flutter pub get
   flutter run -d chrome --dart-define-from-file=.env
   ```

Альтернативно для разработчиков, у которых не настроен браузер или CI:

```powershell
cd client
flutter test --dart-define-from-file=.env
flutter build web --debug --dart-define-from-file=.env
```

## Дополнительные тулчейны

- **Supabase CLI** — если нет `scoop`/`winget`/`choco`, можно скачать релиз в локальную папку `.tools/` (уже gitignored):
  ```powershell
  New-Item -ItemType Directory -Force .tools | Out-Null
  $tag = (Invoke-RestMethod "https://api.github.com/repos/supabase/cli/releases/latest").tag_name
  Invoke-WebRequest -Uri "https://github.com/supabase/cli/releases/download/$tag/supabase_windows_amd64.tar.gz" -OutFile .tools/supabase.tar.gz -UseBasicParsing
  tar -xzf .tools/supabase.tar.gz -C .tools/
  ```
  Используется как `.\.tools\supabase.exe <command>`.
- **Docker Desktop** — нужен для `supabase start` (локальный Postgres/Auth/Realtime) и для self-hosted LiveKit в Phase 3.

## Статус

В разработке. Текущая фаза: **Phase 4 — Текстовый чат** (Phase 3 — 1-на-1 Calls закрыта).

Закрытые шаги Phase 0:
- 0.1 — bootstrap репозитория (`f148eb5`)
- 0.2 — Flutter scaffold (`1ab4576`)
- 0.3 — Supabase CLI scaffold (`ed50a1b`)
- 0.4 — env-loading (`16ed893`)
- 0.5 — Локализация ru/en (`34bba8b`)
- 0.6 — Riverpod + go_router + Theme скелет (`c3912e6`, fix-up `38c6156`)
- 0.7 — CI: GitHub Actions (`7c46ca7`)

Закрытые шаги Phase 1:
- 1.1 — profiles migration + auth trigger (`93d398c`)
- 1.2 — profiles RLS policies (`e399864`)
- 1.3 — pg_trgm search indexes (`b1a3ba2`)
- 1.4 — RPC username_available (`2c6d04d`)
- 1.5 — auth sign up / in / out (`1baa915`)
- 1.6 — onboarding username + display name (`5939a91`)
- 1.7 — profile + avatars storage (`0c39de1`)

Phase 1 закрыта (`0c39de1`).

Закрытые шаги Phase 2:
- 2.1 — contacts table + RLS (`d841c21`)
- 2.2 — RPC search_users (`2ffd066`)
- 2.3 — contacts lists + realtime (`dd19671`)
- 2.4 — user search UI (`03f622a`)
- 2.5 — global presence online indicators (`c0a11c5`)

Phase 2 закрыта (`c0a11c5`).

Закрытые шаги Phase 3:
- 3.1 — call_invitations + call_history migrations (`53c8db4`)
- 3.2 — LiveKit dev + Cloudflare Tunnel (`c338da7`)
- 3.3 — Edge Functions for LiveKit tokens (`d6a9d93`, fix-up `c929d30`)
- 3.4 — pg_cron call invitation timeout (`d211234`)
- 3.5 — Call data layer (`e0f818d`)
- 3.6 — CallController (`5b9b081`)
- 3.7 — incoming call listener + overlay (`966f117`)
- 3.8 — active call screen + outgoing call UI (`9122161`)
- 3.9 — call history screen + terminal archive fix (`cd2f329`, fix-up `1f2745c`)

Phase 3 закрыта (`1f2745c`).

Закрытые шаги Phase 4:
- 4.1 — conversations + messages migrations (`12273f6`)
- 4.2 — chat repository + realtime (`eef2a25`, migration `0018`)
- 4.3 — chat UI: conversations + chat screens (`f383f71`)
- 4.3.1 — message sound + unread badges (`1890e04`)
- 4.3.2 — per-contact unread badge on chat action (`3f12d25`)

Phase 4 (core) закрыта. Следующий шаг (polish): **4.4** — чат во время звонка.

## Лицензия

MIT — см. [LICENSE](LICENSE).
