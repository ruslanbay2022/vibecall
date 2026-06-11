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

- **Step 6.2** — DuckDNS (динамический DNS)
- **Step 6.3** — `infra/prod/docker-compose.yml` + Caddy + LiveKit
- **Step 6.4** — `ufw.sh` на VM

Конфиги LiveKit и Caddy будут добавлены в соответствующих шагах — не раньше.
