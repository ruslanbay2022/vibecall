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

`network_mode: host` на Docker Desktop **не работает как на Linux**. `cloudflared` в compose использует bridge + `host.docker.internal`.

```powershell
cd infra/dev
docker compose -f docker-compose.windows.yml up -d
```

**Cloudflare Zero Trust → Tunnel → Public Hostname → Service URL** (обязательно на Windows):

```
http://host.docker.internal:7880
```

Не `localhost:7880` — из контейнера это не ваш LiveKit на хосте.

**Альтернатива (проще):** установить [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/) на Windows и запускать **вне Docker**:

```powershell
cloudflared tunnel --protocol http2 run --token <CF_TUNNEL_TOKEN>
```

Тогда в Dashboard можно оставить `http://localhost:7880`.

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
   └── cloudflared (bridge) ── origin http://host.docker.internal:7880
        │
        └── wss://vibecall-lk-dev.<domain> (публичный)
```

На Windows **не используйте** `network_mode: host` для cloudflared. Либо compose + `host.docker.internal` в Dashboard, либо cloudflared natively на хосте + `localhost:7880`.

### UDP / TCP

Cloudflare Tunnel не проксирует UDP. Media будет использовать TCP fallback на порт 7881. Для dev этого достаточно. Production-конфиг использует TURN-over-TLS (Phase 6).

### Localhost dev (Windows Docker) — ICE / MediaConnectException

LiveKit в Docker по умолчанию рекламирует IP контейнера (`172.19.0.2`) в ICE candidates. Браузер на хосте до него не достучится → `Timed out waiting for PeerConnection`.

В `livekit-dev.yaml` задано `use_external_ip: false` и `node_ip: 127.0.0.1` (не `use_external_ip: true` — иначе STUN подставит публичный IP). После изменения:

```powershell
docker compose -f docker-compose.windows.yml restart livekit
```

Для QA на **одном ПК**: `LIVEKIT_WS_URL=ws://127.0.0.1:7880` (client `.env` + Supabase secrets). Два клиента: **Chrome + Edge**.

### Cloudflare Tunnel — 502 / 530 / звонок падает на wss://

1. **Проверка сигналинга:**
   ```powershell
   curl.exe -I https://vibecall-lk-dev.<ваш-домен>
   ```
   Ожидается **200** или **426 Upgrade Required**. **502/530** — туннель не доходит до LiveKit или нет связи с Cloudflare.

2. **Windows + Docker:** Service URL в Dashboard = `http://host.docker.internal:7880` (см. раздел Windows выше).

3. **QUIC timeout в логах** (`failed to dial to edge with quic`):
   ```powershell
   docker logs dev-cloudflared-1 --tail 30
   ```
   Compose форсирует `--protocol http2`. Если всё равно timeout — firewall/провайдер блокирует исходящий **TCP/UDP 7844** к Cloudflare.

4. **Даже при рабочем wss://** media (WebRTC) идёт **не через туннель**, а на **7881/tcp** и UDP 50000–50200 на ваш ПК. С `node_ip: 127.0.0.1` это OK на одном ПК; для телефона по 4G нужен другой ICE-конfig (Phase 6).

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
