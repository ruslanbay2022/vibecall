# LiveKit Production Environment — Oracle Cloud Always Free VM

Production LiveKit-сервер на Oracle Cloud Infrastructure (Always Free) с последующим DuckDNS, Caddy и LiveKit.

## §1 Prerequisites

- **Oracle Cloud** аккаунт (Always Free) — потребуется карта для верификации
- **SSH клиент** (Windows: OpenSSH / PuTTY; Linux/macOS: встроенный)
- **Публичный SSH ключ** — если нет, создать:

```bash
ssh-keygen -t ed25519 -C "vibecall-prod"
```

---

## §2 Oracle Cloud — создать VM (ручной чеклист)

1. **https://cloud.oracle.com** → Sign up / Sign in (Always Free, карта для верификации).
2. **Compute → Instances → Create instance**:
   - **Name:** `vibecall-prod`
   - **Image:** Ubuntu 22.04 LTS (aarch64)
   - **Shape:** `VM.Standard.A1.Flex` — **2 OCPU, 12 GB RAM** (в лимите 4 OCPU / 24 GB)
   - **Networking:** default VCN, **assign public IPv4**
   - **SSH keys:** вставить **public** key пользователя
3. Дождаться статуса **RUNNING**, записать **Public IP**.
4. **Если A1 недоступен** в Availability Domain — попробовать другой AD / регион; **не** переключаться на платный shape без согласования.

---

## §3 OCI Security List — ingress правила

**До** deploy LiveKit открыть: **Networking → VCN → Security Lists → Default → Ingress Rules**.

| Port(s) | Protocol | Source | Назначение |
|---------|----------|--------|------------|
| 22 | TCP | `0.0.0.0/0` (или ваш IP) | SSH |
| 80 | TCP | `0.0.0.0/0` | Caddy HTTP → Let's Encrypt |
| 443 | TCP | `0.0.0.0/0` | HTTPS / WSS |
| 7881 | TCP | `0.0.0.0/0` | WebRTC TCP fallback |
| 3478 | UDP | `0.0.0.0/0` | STUN |
| 5349 | TCP, UDP | `0.0.0.0/0` | TURN-over-TLS |
| 50000–60000 | UDP | `0.0.0.0/0` | RTP media |

OCI Security List **обязателен** — без него трафик не дойдёт даже при открытом UFW на VM. UFW настраивается в **Step 6.4**.

---

## §4 Bootstrap VM (после первого SSH)

```bash
ssh ubuntu@<PUBLIC_IP>
```

Скопировать и запустить скрипт из репо:

```bash
# Локально — scp
scp infra/prod/bootstrap-vm.sh ubuntu@<PUBLIC_IP>:~/

# На VM
ssh ubuntu@<PUBLIC_IP> 'bash ~/bootstrap-vm.sh'
```

**После завершения скрипта** — выйти из SSH и зайти снова (`exit` → `ssh ubuntu@<PUBLIC_IP>`), иначе `docker` без sudo не сработает.

---

## §5 Verification

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Ожидание: hello-world exit 0, сообщение `Hello from Docker!`.

---

## §6 Что дальше

- **Step 6.2** — DuckDNS (динамический DNS)
- **Step 6.3** — `infra/prod/docker-compose.yml` + Caddy + LiveKit
- **Step 6.4** — `ufw.sh` + повторная сверка Security List

Конфиги LiveKit и Caddy будут добавлены в соответствующих шагах — не раньше.
