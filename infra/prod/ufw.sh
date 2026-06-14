#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)." >&2
  exit 1
fi

ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'Caddy HTTP LE'
ufw allow 443/tcp comment 'HTTPS WSS'
ufw allow 7881/tcp comment 'WebRTC TCP'
ufw allow 3478/udp comment 'STUN'
ufw allow 5349/tcp comment 'TURN TLS'
ufw allow 5349/udp comment 'TURN TLS'
ufw allow 50000:60000/udp comment 'RTP media'

echo ""
echo "Rules to be applied:"
ufw show added
echo ""
echo "Enabling UFW in 5 seconds — ensure 22/tcp is allowed above."
sleep 5
ufw --force enable
ufw status verbose
