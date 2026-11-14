#!/bin/sh
# Render /etc/xray/config.json from its template and start Xray.
#   PORT — port Xray listens on. Cloady serves a no-compose app on 3000
#          unless PORT names another; the compose file pins 3000.
#   UUID — the single VLESS client id. Set it as a SECRET variable in
#          Cloady (Settings -> Environment) at deploy time. If it is missing
#          or malformed, a fresh UUID is generated and printed to the log —
#          read it from the deploy logs and use it in the client link.
set -eu

PORT="${PORT:-3000}"
UUID="${UUID:-}"

case "$PORT" in
  ''|*[!0-9]*)
    echo "ERROR: PORT must be a number, got '$PORT'" >&2
    exit 1
    ;;
esac

is_uuid() {
  case "$1" in
    ????????-????-????-????-????????????) return 0 ;;
    *) return 1 ;;
  esac
}

if ! is_uuid "$UUID"; then
  UUID="$(cat /proc/sys/kernel/random/uuid)"
  echo "WARNING: UUID env var missing or malformed — generated fresh UUID: $UUID"
  echo "WARNING: set UUID=$UUID as a secret variable in Cloady and redeploy to keep it stable."
fi

echo "Starting Xray on 0.0.0.0:${PORT} (VLESS + WebSocket, path /vless)"

sed -e "s/__PORT__/${PORT}/g" -e "s/__UUID__/${UUID}/g" \
  /etc/xray/config.json > /tmp/config.json

exec /usr/local/bin/xray run -config /tmp/config.json
