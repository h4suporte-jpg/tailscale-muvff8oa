#!/usr/bin/env bash
set -euo pipefail
set -x

TAILSCALE_VERSION=${TAILSCALE_VERSION:-1.96.4}
TS_FILE="tailscale_${TAILSCALE_VERSION}_amd64.tgz"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

wget -q -O "$TMP_DIR/$TS_FILE" "https://pkgs.tailscale.com/stable/${TS_FILE}"
tar xzf "$TMP_DIR/$TS_FILE" -C "$TMP_DIR" --strip-components=1
install -m 0755 "$TMP_DIR/tailscale" /render/tailscale
install -m 0755 "$TMP_DIR/tailscaled" /render/tailscaled
mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale
