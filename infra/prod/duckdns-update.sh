#!/usr/bin/env bash
set -euo pipefail

DUCKDNS_ENV_FILE="${DUCKDNS_ENV_FILE:-/etc/duckdns/duckdns.env}"

if [[ ! -f "$DUCKDNS_ENV_FILE" ]]; then
  echo "Error: $DUCKDNS_ENV_FILE not found. Copy duckdns.env.example to /etc/duckdns/duckdns.env and set token." >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$DUCKDNS_ENV_FILE"

if [[ -z "${DUCKDNS_DOMAIN:-}" || -z "${DUCKDNS_TOKEN:-}" ]]; then
  echo "Error: DUCKDNS_DOMAIN and DUCKDNS_TOKEN must be set in $DUCKDNS_ENV_FILE" >&2
  exit 1
fi

RESPONSE=$(curl -fsS "https://www.duckdns.org/update?domains=${DUCKDNS_DOMAIN}&token=${DUCKDNS_TOKEN}&ip=" 2>&1)

if [[ "$RESPONSE" != "OK" ]]; then
  echo "Error: DuckDNS returned: $RESPONSE" >&2
  exit 1
fi

echo "OK — $(date)"
