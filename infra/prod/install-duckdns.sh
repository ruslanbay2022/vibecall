#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p /etc/duckdns
chown root:ubuntu /etc/duckdns
chmod 750 /etc/duckdns

if [[ ! -f /etc/duckdns/duckdns.env ]]; then
  echo ""
  echo "=== /etc/duckdns/duckdns.env not found ==="
  echo "Copy the example and set your token:"
  echo "  sudo cp $SCRIPT_DIR/duckdns.env.example /etc/duckdns/duckdns.env"
  echo "  sudo nano /etc/duckdns/duckdns.env   # вставить token"
  echo "  sudo bash $SCRIPT_DIR/install-duckdns.sh   # выставит права и cron"
  exit 1
fi

chown root:ubuntu /etc/duckdns/duckdns.env
chmod 640 /etc/duckdns/duckdns.env

cp "$SCRIPT_DIR/duckdns-update.sh" /usr/local/bin/duckdns-update
chmod 755 /usr/local/bin/duckdns-update

touch /var/log/duckdns-update.log
chown ubuntu:ubuntu /var/log/duckdns-update.log
chmod 644 /var/log/duckdns-update.log

sudo -u ubuntu /usr/local/bin/duckdns-update >> /var/log/duckdns-update.log 2>&1

CRON_JOB="*/5 * * * * /usr/local/bin/duckdns-update >> /var/log/duckdns-update.log 2>&1"
if ! crontab -l -u ubuntu 2>/dev/null | grep -Fq "$CRON_JOB"; then
  (crontab -l -u ubuntu 2>/dev/null; echo "$CRON_JOB") | crontab -u ubuntu -
  echo "Cron installed for user ubuntu."
else
  echo "Cron already present."
fi

echo ""
echo "DuckDNS install done."
echo "Verify: dig +short vibecall.duckdns.org"
