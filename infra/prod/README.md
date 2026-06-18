# LiveKit Production Environment — FirstVDS VPS

Production LiveKit-сервер на **FirstVDS** (KVM VDS, Москва) с последующим DuckDNS, Caddy и LiveKit.

> **Контекст:** изначально PLAN предполагал Oracle Always Free ($0); регистрация OCI недоступна → prod VM на FirstVDS (~500–900 ₽/мес). См. `PLAN.md` Step 6.1.

## §1 Prerequisites

- **FirstVDS** аккаунт — https://firstvds.ru (карта, СБП, ЮMoney)
- **SSH клиент** (Windows: OpenSSH / PuTTY)
- **Публичный SSH ключ** — если нет:

```bash
ssh-keygen -t ed25519 -C "vibecall-prod"
```

## §2 FirstVDS — заказ VDS (ручной чеклист)

1. **https://firstvds.ru** → регистрация / вход.
2. **Готовые серверы 10.0** → тариф **Разгон** (или эквивалент):
   - **2 vCPU**, **4 GB RAM**, **40 GB SSD**
   - **1× IPv4** (включён), канал **безлимит** (до 1–10 Гбит/с по тарифу)
   - **OS:** Ubuntu 22.04 LTS
   - **ДЦ:** Москва (WEB DC / IXcellerate)
   - **SSH keys:** вставить **public** key
   - **Не заказывать:** Windows, ispmanager (TLS — Caddy в Step 6.3)
3. Дождаться активации, записать **Public IP**.
4. Пользователь SSH — `root` или `ubuntu` (смотри письмо / панель FirstVDS).

**Не брать Прогрев (1 GB RAM)** — недостаточно для LiveKit + Docker.

## §3 Порты (UFW на Step 6.4)

На FirstVDS KVM **нет** отдельного cloud firewall (в отличие от Oracle OCI Security List). Порты открываются **UFW на VM** в Step 6.4:

| Port(s) | Protocol | Назначение |
|---------|----------|------------|
| 22 | TCP | SSH |
| 80 | TCP | Caddy HTTP → Let's Encrypt |
| 443 | TCP | HTTPS / WSS |
| 7881 | TCP | WebRTC TCP fallback |
| 3478 | UDP | STUN |
| 5349 | TCP, UDP | TURN-over-TLS |
| 50000–60000 | UDP | RTP media |

До Step 6.4 **не включать** `ufw enable` — риск потерять SSH. Правила применяются через `ufw.sh` (§9).

## §4 Bootstrap VM (после первого SSH)

```powershell
# Windows — FirstVDS выдаёт ubuntu + .pem ключ
ssh -i "D:\VPS\privatekey-XXXX.pem" ubuntu@<PUBLIC_IP>
```

Скопировать и запустить скрипт из репо (с локального ПК, корень репозитория):

```powershell
# Windows PowerShell
$key = "D:\VPS\privatekey-XXXX.pem"
scp -i $key infra/prod/bootstrap-vm.sh ubuntu@<PUBLIC_IP>:~/
ssh -i $key ubuntu@<PUBLIC_IP> "sed -i 's/\r$//' ~/bootstrap-vm.sh && bash ~/bootstrap-vm.sh"
```

```bash
# Linux / macOS
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/bootstrap-vm.sh ubuntu@<PUBLIC_IP>:~/
ssh -i ~/.ssh/firstvds-vibecall.pem ubuntu@<PUBLIC_IP> 'bash ~/bootstrap-vm.sh'
```

**Windows:** на `.pem` только твой пользователь `(R)` в `icacls`, иначе `UNPROTECTED PRIVATE KEY FILE`.  
**Ubuntu 22.04 FirstVDS:** пакет `docker-compose-v2` (не `docker-compose-plugin`).

**После скрипта** — выйти и зайти снова (`exit` → `ssh <user>@<PUBLIC_IP>`), иначе `docker` без sudo не сработает.

## §5 Verification

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Ожидание: hello-world exit 0, сообщение `Hello from Docker!`.

## §6 Что дальше

- **Step 6.2** — DuckDNS — **done** (§7)
- **Step 6.3** — Caddy + LiveKit — **done** (§8)
- **Step 6.4** — `ufw.sh` — **done** (§9)
- **Step 6.5** — Supabase secrets — **done** (§10)
- **Step 6.6** — Cloudflare Pages — **done** (`infra/pages/README.md`)
- **Step 6.7** — Android APK release — **done** (§11)

---

## §7 DuckDNS (Step 6.2)

DuckDNS предоставляет бесплатный динамический DNS для поддомена `vibecall.duckdns.org`.

### 7.1 Регистрация

1. Открой https://www.duckdns.org → войти через один из провайдеров (GitHub, Google, Twitter).
2. В поле **domains** введи **`vibecall`** → кнопка **add domain**.
3. Скопируй **token** (понадобится на VDS).

### 7.2 Установка на VDS

```powershell
# Windows (см. §4 — путь к .pem)
$key = "D:\VPS\privatekey-XXXX.pem"
scp -i $key infra/prod/duckdns-update.sh ubuntu@<PUBLIC_IP>:~/
scp -i $key infra/prod/duckdns.env.example ubuntu@<PUBLIC_IP>:~/
scp -i $key infra/prod/install-duckdns.sh ubuntu@<PUBLIC_IP>:~/

ssh -i $key ubuntu@<PUBLIC_IP> "sed -i 's/\r$//' ~/*.sh && sudo bash ~/install-duckdns.sh"
```

Установщик:
- Создаёт `/etc/duckdns/` — **`chown root:ubuntu` + `chmod 750`** (ubuntu cron должен traverse каталог для чтения env)
- Копирует `duckdns-update.sh` → `/usr/local/bin/duckdns-update`
- **`chown root:ubuntu` + `chmod 640`** на `duckdns.env` — cron пользователя `ubuntu` может читать token
- Если `/etc/duckdns/duckdns.env` отсутствует — **останавливается с инструкцией**:

```bash
sudo cp duckdns.env.example /etc/duckdns/duckdns.env
sudo nano /etc/duckdns/duckdns.env   # вставить реальный token
```

Повторно запустить установщик после создания env:

```bash
sudo bash ~/install-duckdns.sh
```

Установщик также добавляет cron (`*/5 * * * *`) для пользователя `ubuntu` и проверяет update от имени `ubuntu`.

### 7.3 Verification

```bash
dig +short vibecall.duckdns.org
# Ожидание: IP твоей VDS (curl -4 ifconfig.me)
```

Windows: `nslookup vibecall.duckdns.org` или `Resolve-DnsName vibecall.duckdns.org`.

### 7.4 Обновление вручную

```bash
/usr/local/bin/duckdns-update
```

Лог: `/var/log/duckdns-update.log` (владелец `ubuntu`).

---

## §8 Caddy + LiveKit deploy (Step 6.3)

LiveKit + Caddy на prod VDS с автоматическим Let's Encrypt TLS.

### 8.1 Файлы в репо

| Файл | Назначение |
|------|------------|
| `docker-compose.yml` | LiveKit (`v1.7.2`) + Caddy (`2-alpine`), оба `network_mode: host` |
| `livekit-prod.yaml` | Prod config: RTC 7881/tcp + 50000–60000/udp, TURN 3478+5349 (без keys в yaml) |
| `Caddyfile` | Reverse proxy `vibecall.duckdns.org` → `localhost:7880`; авто ACME |
| `.env.example` | Шаблон для `LIVEKIT_API_KEY` / `LIVEKIT_API_SECRET` |

**Keys:** `docker-compose.yml` передаёт `--keys` из `.env` (LiveKit не раскрывает `${VAR}` в yaml).

**Networking:** оба сервиса в `network_mode: host` → Caddy видит LiveKit на `localhost:7880`; Let's Encrypt challenge на портах 80/443 напрямую.

**TURN/TLS (5349):** `external_tls: true` — полный TURN-over-TLS через L4 proxy в Step 6.4+; для 6.3 достаточно HTTPS/WSS + `list-rooms`.

### 8.2 Deploy на VDS

```powershell
# Windows — копирование файлов на VDS (корень репозитория)
$key = "D:\VPS\privatekey-XXXX.pem"
$files = @(
  "infra/prod/docker-compose.yml",
  "infra/prod/Caddyfile",
  "infra/prod/livekit-prod.yaml",
  "infra/prod/.env.example"
)
foreach ($f in $files) {
  scp -i $key $f ubuntu@<PUBLIC_IP>:~/
}
```

```bash
# Linux / macOS
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/docker-compose.yml ubuntu@<PUBLIC_IP>:~/
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/Caddyfile ubuntu@<PUBLIC_IP>:~/
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/livekit-prod.yaml ubuntu@<PUBLIC_IP>:~/
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/.env.example ubuntu@<PUBLIC_IP>:~/
```

Все файлы должны быть **в одной директории** на VDS (например `~/`). Запуск `docker compose` — из этой директории.

### 8.3 Генерация prod keys и `.env`

На VDS (в каталоге с `docker-compose.yml`):

```bash
# Сгенерировать ключи на VDS (НЕ в PowerShell one-liner — openssl только на Linux)
LIVEKIT_API_KEY="API$(openssl rand -hex 8)"
LIVEKIT_API_SECRET=$(openssl rand -base64 32)

# Создать .env (echo, не sed — secret может содержать / + =)
{
  echo "LIVEKIT_API_KEY=$LIVEKIT_API_KEY"
  echo "LIVEKIT_API_SECRET=$LIVEKIT_API_SECRET"
} > .env
chmod 600 .env
```

Альтернатива: `cp .env.example .env` и `nano .env`.

**Сохранить значения** `LIVEKIT_API_KEY` и `LIVEKIT_API_SECRET` — они понадобятся в Step 6.5 (`supabase secrets set`).

### 8.4 Запуск

```bash
docker compose up -d
docker compose ps
```

Первый Let's Encrypt сертификат может занять ~1 минуту:

```bash
docker compose logs -f caddy   # ждать "certificate obtained successfully"
```

### 8.5 Verification

```bash
curl -I https://vibecall.duckdns.org
# Ожидание: HTTP/2 200 (или 404 — оба без cert error)

livekit-cli list-rooms --url wss://vibecall.duckdns.org \
  --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET"
# Ожидание: exit 0, пустой список
```

### 8.6 Stop / Restart

```bash
docker compose down
docker compose up -d
docker compose logs -f livekit caddy
```

---

## §9 UFW (Step 6.4)

Файрвол `ufw` на VDS — основной барьер (FirstVDS KVM без cloud firewall).

### 9.1 Правила

| Port(s) | Protocol | Назначение |
|---------|----------|------------|
| 22 | TCP | SSH |
| 80 | TCP | Caddy HTTP → Let's Encrypt |
| 443 | TCP | HTTPS / WSS |
| 7881 | TCP | WebRTC TCP fallback |
| 3478 | UDP | STUN |
| 5349 | TCP, UDP | TURN-over-TLS |
| 50000–60000 | UDP | RTP media |

Порт **7880** (LiveKit сигналинг) **не** открывается — только 443 через Caddy.

### 9.2 Установка

```powershell
# Windows (корень репозитория)
$key = "D:\VPS\privatekey-XXXX.pem"
scp -i $key infra/prod/ufw.sh ubuntu@<PUBLIC_IP>:~/
ssh -i $key ubuntu@<PUBLIC_IP> "sed -i 's/\r$//' ~/ufw.sh && sudo bash ~/ufw.sh"
```

```bash
# Linux / macOS
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/ufw.sh ubuntu@<PUBLIC_IP>:~/
ssh -i ~/.ssh/firstvds-vibecall.pem ubuntu@<PUBLIC_IP> 'sudo bash ~/ufw.sh'
```

Скрипт:
- Показывает правила до `enable` + задержка 5 сек
- Идемпотентен — повторный запуск безопасен
- **Не отключает** существующие Docker-правила

### 9.3 Verification

С локального ПК (Windows / Linux):

```powershell
nmap -p 443,3478,5349,50000-50005 vibecall.duckdns.org
```

Ожидание: `open` на 443/tcp, `open|filtered` на UDP (nmap UDP может требовать admin).

После UFW проверить что HTTPS работает:

```bash
curl -I https://vibecall.duckdns.org
```

### 9.4 Что дальше

- **Step 6.5** — Supabase secrets — **done** (§10)
- **Step 6.6** — Cloudflare Pages — **done** (`infra/pages/README.md`)
- **Step 6.7** — Android APK release — **done** (§11)

---

## §10 Supabase secrets — prod LiveKit (Step 6.5)

Переключение Edge Functions на prod LiveKit (`wss://vibecall.duckdns.org`).

### 10.1 Предусловия

- Prod keys из VDS `~/.env` (Step 6.3) — сохранены в password manager, **не в git**
- Supabase CLI: `supabase login`, `supabase link` к **prod** проекту
- Edge Functions уже задеплоены (Phase 3)

### 10.2 Set secrets

**Команда** (подставить реальные значения из VDS, **не** коммитить):

```bash
supabase secrets set \
  LIVEKIT_WS_URL=wss://vibecall.duckdns.org \
  LIVEKIT_API_KEY=<prod-from-vds-env> \
  LIVEKIT_API_SECRET=<prod-from-vds-env>
```

Проверить (без вывода secret):

```bash
supabase secrets list
# LIVEKIT_WS_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET — present
```

### 10.3 Redeploy (опционально)

Secrets подхватываются Edge runtime. При сомнениях:

```bash
supabase functions deploy generate-call-token
supabase functions deploy accept-call
```

### 10.4 Тест звонка

**Manual QA 2026-06:** prod `secrets set` + звонок Desktop + Web — OK (Chrome/Desktop стабильнее Edge для WSS с localhost).

1. Два клиента (Web: Chrome + Edge, или Desktop) с `client/.env` → **prod Supabase** URL/anon key
2. Исходящий звонок → callee принимает → аудио/видео
3. На VDS: комната появляется на время звонка:

```bash
livekit-cli list-rooms --url wss://vibecall.duckdns.org \
  --api-key "$LIVEKIT_API_KEY" --api-secret "$LIVEKIT_API_SECRET"
```

4. Опционально: callee на **4G** (NAT/TURN; не блокер — инфра готова)

### 10.5 Dev после prod switch

- Edge secrets = prod → локальный dev LiveKit tunnel **не используется** для облачных звонков
- Локальный dev: отдельный Supabase project или временно вернуть dev secrets (вручную)
- `LIVEKIT_WS_URL` в `client/.env` — fallback; звонки используют `wsUrl` из ответа Edge Function

---

## §11 Android release APK (Step 6.7)

### 11.1 Keystore (один раз, локально)

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Base64 для GitHub Secret:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks"))
```

### 11.2 GitHub Secrets

Repo Settings → Secrets and variables → Actions:

| Secret | Value |
|--------|-------|
| `ANDROID_KEYSTORE_BASE64` | base64 of `.jks` |
| `ANDROID_KEY_ALIAS` | e.g. `upload` |
| `ANDROID_KEY_PASSWORD` | key password |
| `ANDROID_STORE_PASSWORD` | store password |
| `PROD_SUPABASE_URL` | `https://<ref>.supabase.co` |
| `PROD_SUPABASE_ANON_KEY` | anon public key |

### 11.3 Release

```powershell
git tag v0.1.3
git push origin v0.1.3
```

GitHub → Releases → APK + desktop zips (`desktop_release.yml` запускается параллельно на тот же tag). Если в release только один тип артефакта — подождать второй workflow или Re-run failed jobs.

### 11.4 Verify

Установить APK на Android → sign-in → prod звонок (audio/video, ringback, permissions).

**Manual QA 2026-06:** `v0.1.0` — install + sign-in OK. **v0.1.3** — prod звонок Android ↔ desktop OK; media/wakelock #92, camera #93, ringback/disconnect #96.

**MIUI / Xiaomi:** если звонок обрывается в фоне — Настройки → Приложения → VibeCall → **Без ограничений** (энергосбережение). Wakelock (#92) держит экран; агрессивный фон может всё ещё требовать ручной whitelist.

> Troubleshooting (Auth, ringback, camera, VPN) — см. [README.md §Troubleshooting](../../README.md#troubleshooting).
