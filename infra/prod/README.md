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

До Step 6.4 **не включать** `ufw enable` — риск потерять SSH.

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

- **Step 6.2** — DuckDNS (динамический DNS) — см. §7
- **Step 6.3** — `infra/prod/docker-compose.yml` + Caddy + LiveKit
- **Step 6.4** — `ufw.sh` на VM

Конфиги LiveKit и Caddy будут добавлены в соответствующих шагах — не раньше.

---

## §7 DuckDNS (Step 6.2)

DuckDNS предоставляет бесплатный динамический DNS для поддомена `vibecall.duckdns.org`.

### 7.1 Регистрация

1. Открой https://www.duckdns.org → войти через один из провайдеров (GitHub, Google, Twitter).
2. В поле **domains** введи **`vibecall`** → кнопка **add domain**.
3. Скопируй **token** (понадобится на VDS).

### 7.2 Установка на VDS

```bash
# С локальной машины (корень репозитория)
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/duckdns-update.sh ubuntu@<PUBLIC_IP>:~/
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/duckdns.env.example ubuntu@<PUBLIC_IP>:~/
scp -i ~/.ssh/firstvds-vibecall.pem infra/prod/install-duckdns.sh ubuntu@<PUBLIC_IP>:~/

# На VDS
ssh -i ~/.ssh/firstvds-vibecall.pem ubuntu@<PUBLIC_IP> 'sudo bash ~/install-duckdns.sh'
```

Установщик:
- Создаёт `/etc/duckdns/` (mode 700)
- Копирует `duckdns-update.sh` → `/usr/local/bin/duckdns-update`
- Если `/etc/duckdns/duckdns.env` отсутствует — **останавливается с инструкцией**:

```bash
sudo cp duckdns.env.example /etc/duckdns/duckdns.env
sudo chmod 600 /etc/duckdns/duckdns.env
sudo nano /etc/duckdns/duckdns.env   # вставить реальный token
```

Повторно запустить установщик после создания env:

```bash
sudo bash ~/install-duckdns.sh
```

Установщик также добавляет cron (`*/5 * * * *`) для пользователя `ubuntu`.

### 7.3 Verification

```bash
dig +short vibecall.duckdns.org
# Ожидание: IP твоей VDS (curl -4 ifconfig.me)
```

Windows: `nslookup vibecall.duckdns.org` или `Resolve-DnsName vibecall.duckdns.org`.

### 7.4 Обновление вручную

```bash
sudo /usr/local/bin/duckdns-update
```

Лог: `/var/log/duckdns-update.log`.
