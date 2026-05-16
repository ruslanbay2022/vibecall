# VibeCall

Кроссплатформенный аналог Skype: 1‑на‑1 аудио/видео-звонки, текстовый чат, демонстрация экрана. Web → Android → Desktop → iOS.

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

В разработке. Текущая фаза: **Phase 0 — Foundation**.

Закрытые шаги:
- 0.1 — bootstrap репозитория (`f148eb5`)
- 0.2 — Flutter scaffold (`1ab4576`)
- 0.3 — Supabase CLI scaffold (`ed50a1b`)
- 0.4 — env-loading (`16ed893`)

## Лицензия

MIT — см. [LICENSE](LICENSE).
