# LiveKit Dev Environment

Локальный LiveKit-сервер с публичным HTTPS-адресом через Cloudflare Tunnel для разработки.

## Prerequisites

- Docker Desktop (Windows) / Docker Engine (Linux/macOS)
- Cloudflare аккаунт (бесплатный) — https://dash.cloudflare.com/
- Cloudflare Zero Trust tunnel `vibecall-dev` (см. ниже)

## 1. Cloudflare Tunnel (один раз)

1. Zero Trust → Networks → Tunnels → **Create a tunnel**.
2. Name: `vibecall-dev`.
3. Выберите **cloudflared** (any OS) — токен будет показан один раз.
4. **Public Hostname**:
   - Subdomain: `vibecall-lk-dev`
   - Domain: ваш домен (или используйте бесплатный `trycloudflare.com` для теста)
   - Service: `http://localhost:7880`
5. Сохраните токен.
6. Скопируйте `infra/dev/cloudflared.example.env` → `infra/dev/.env`:
   ```powershell
   Copy-Item infra/dev/cloudflared.example.env infra/dev/.env
   ```
7. Вставьте токен в `infra/dev/.env`:
   ```
   CF_TUNNEL_TOKEN=<токен-из-cloudflare>
   ```

## 2. Запуск

### Linux / macOS

```bash
cd infra/dev
docker compose up -d
```

### Windows

`network_mode: host` не работает на Windows. Используйте отдельный compose-файл:

```powershell
cd infra/dev
docker compose -f docker-compose.windows.yml up -d
```

### Что поднимается

- **LiveKit** — на `localhost:7880` (сигналинг), `7881/tcp` (WebRTC TCP fallback), `50000-50200/udp` (RTP media).
- **cloudflared** — туннель на `vibecall-lk-dev.<ваш-домен>` → `localhost:7880`.

## 3. Проверка

```bash
# HTTP(S) endpoint (должен вернуть 426 Upgrade Required — это нормально)
curl -I https://vibecall-lk-dev.<ваш-домен>

# WebSocket через wscat (установите: npm install -g wscat)
wscat -c wss://vibecall-lk-dev.<ваш-домен>
```

## 4. Настройка клиента

В `client/.env` добавить:

```
LIVEKIT_WS_URL=wss://vibecall-lk-dev.<ваш-домен>
```

## 5. Edge Functions (позже, Step 3.3)

```bash
supabase secrets set LIVEKIT_API_KEY=devkey LIVEKIT_API_SECRET=devsecretdevsecretdevsecretdevse LIVEKIT_WS_URL=wss://vibecall-lk-dev.<ваш-домен>
```

## Архитектура

### Linux / macOS

```
LiveKit (host network) ── порты 7880, 7881, 50000-50200
   │
   └── cloudflared (host network) ── TCP 443/7881 → LiveKit 7880
        │
        └── wss://vibecall-lk-dev.<domain> (публичный)
```

### Windows

```
LiveKit (ports: 7880, 7881, 50000-50200/udp)
   │
   └── cloudflared (host network) ── TCP 443/7881 → host.docker.internal:7880
        │
        └── wss://vibecall-lk-dev.<domain> (публичный)
```

На Windows **cloudflared** работает в host network и обращается к `localhost:7880` (проброшен через порты контейнера).

### UDP / TCP

Cloudflare Tunnel не проксирует UDP. Media будет использовать TCP fallback на порт 7881. Для dev этого достаточно. Production-конфиг использует TURN-over-TLS (Phase 6).

## Остановка

```bash
# Linux / macOS
docker compose down

# Windows
docker compose -f docker-compose.windows.yml down
```

## Очистка (полностью удалить образы)

```bash
docker compose down --rmi all -v
```
