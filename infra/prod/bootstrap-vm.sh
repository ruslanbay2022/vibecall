#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as normal user (ubuntu), not root. Script uses sudo." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y upgrade
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install \
  docker.io docker-compose-plugin ufw curl ca-certificates

sudo usermod -aG docker "$USER"

echo ""
echo "Bootstrap done. Log out and SSH back in, then run:"
echo "  docker run --rm hello-world"
echo "  docker compose version"
