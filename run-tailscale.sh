#!/usr/bin/env bash
set -euo pipefail

/render/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
TAILSCALED_PID=$!

ADVERTISE_ROUTES=${ADVERTISE_ROUTES:-10.0.0.0/8}
H4C5_TARGET_HOST=${H4C5_TARGET_HOST:-h4c5-panel-private}
H4C5_TARGET_PORT=${H4C5_TARGET_PORT:-3000}
H4C5_BRIDGE_PORT=${H4C5_BRIDGE_PORT:-19000}

until /render/tailscale up \
  --authkey="${TAILSCALE_AUTHKEY}" \
  --hostname="${RENDER_SERVICE_NAME}" \
  --advertise-routes="${ADVERTISE_ROUTES}"; do
  sleep 1
 done

export ALL_PROXY=socks5://localhost:1055/
TAILSCALE_IP=$(/render/tailscale ip -4)
echo "Tailscale is up at IP ${TAILSCALE_IP}"

# Stable H4C5 bridge:
# Tailscale TCP Serve -> localhost -> Render stable internal hostname.
# The H4C5 HMAC signer remains on the administrative PC; this router never
# receives PRIVATE_GATEWAY_KEY.
while ! getent hosts "${H4C5_TARGET_HOST}" >/dev/null 2>&1; do
  echo "Waiting for Render private DNS: ${H4C5_TARGET_HOST}"
  sleep 2
 done

socat \
  "TCP-LISTEN:${H4C5_BRIDGE_PORT},bind=127.0.0.1,reuseaddr,fork,keepalive" \
  "TCP:${H4C5_TARGET_HOST}:${H4C5_TARGET_PORT},connect-timeout=10" &
BRIDGE_PID=$!

/render/tailscale serve --bg \
  --tcp="${H4C5_BRIDGE_PORT}" \
  "tcp://127.0.0.1:${H4C5_BRIDGE_PORT}"

echo "H4C5 stable bridge ready: tailnet TCP ${H4C5_BRIDGE_PORT} -> ${H4C5_TARGET_HOST}:${H4C5_TARGET_PORT}"

cleanup() {
  kill "${BRIDGE_PID}" 2>/dev/null || true
  kill "${TAILSCALED_PID}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait "${TAILSCALED_PID}"
