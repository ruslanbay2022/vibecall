# Cloudflare Pages — Flutter Web release (Step 6.6)

Деплой VibeCall Flutter Web на Cloudflare Pages с продовым Supabase и LiveKit.

## Предусловия

- Cloudflare аккаунт (free) — https://dash.cloudflare.com/
- GitHub repo `ruslanbay2022/vibecall` (или fork) — Pages подключается к Git
- Prod Supabase проект, Edge secrets → prod LiveKit (Step 6.5 / #87)
- Prod LiveKit `wss://vibecall.duckdns.org` — работает через Edge Function `wsUrl`

## Create CF Pages project

1. **Workers & Pages → Create → Pages → Connect to Git**
2. Репозиторий → `main` branch
3. **Build configuration:**
   - **Framework preset:** None
   - **Build command:** `bash infra/pages/build.sh`
   - **Build output directory:** `client/build/web`
   - **Root directory:** `/` (repo root, не `client/`)

## Environment variables (Production)

CF Dashboard → **Settings → Environment variables → Production**:

| Variable | Value |
|----------|-------|
| `SUPABASE_URL` | `https://<project>.supabase.co` |
| `SUPABASE_ANON_KEY` | `<anon-key>` |
| `ENV` | `prod` |
| `SENTRY_DSN` | *(optional)* |
| `LIVEKIT_WS_URL` | `wss://vibecall.duckdns.org` *(optional fallback)* |

**Не коммитить** реальные значения в git.

## Supabase Auth (critical)

После деплоя обновить Supabase Dashboard:

**Authentication → URL Configuration:**
- **Site URL** → `https://<project>.pages.dev`
- **Redirect URLs** → `https://<project>.pages.dev/**`

Без этого email confirm / OAuth redirect сломаны на prod Web.

## Deploy & verify

1. Первый deploy может занять 10–15+ минут (установка Flutter SDK)
2. Открыть `https://<project>.pages.dev`
3. Sign-up / sign-in → должно работать
4. Исходящий звонок с второго клиента (Desktop или другой браузер) → аудио/видео через prod LiveKit
5. Обновить страницу на `/home` — не должно быть 404 (SPA `_redirects`)

## Как это работает

- `infra/pages/build.sh` — устанавливает Flutter 3.41.x, запускает `build_runner` + `flutter build web --release`
- `--dart-define` берутся из CF Environment Variables (не `.env` файла — файла нет на CF builder)
- `client/web/_redirects` — SPA fallback для go_router (`/home`, `/sign-in` и т.д.)
- `LIVEKIT_WS_URL` в build — fallback; звонки получают `wsUrl` из ответа Edge Function (Step 6.5)

## Custom domain (optional)

- CF Pages → **Custom domains** → добавить поддомен (например `www.vibecall.duckdns.org`)
- Обновить Supabase Site URL + Redirect URLs

## Troubleshooting

| Проблема | Проверить |
|----------|-----------|
| Build fail (timeout) | Flutter SDK install ~5–10 min; retry |
| Blank page после refresh | `_redirects` на месте |
| Auth redirect loop | Site URL / Redirect URLs в Supabase → CF Pages URL |
| Call fail | Edge secrets (Step 6.5); `wsUrl` в Network-ответе generate-call-token |
| WebRTC нет | HTTPS required (CF Pages автоматически) |

## Deferred (не в этом PR)

- GitHub Actions → `cloudflare/pages-action` (CI deploy)
- Custom domain на DuckDNS
