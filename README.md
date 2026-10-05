# Render Tailscale subnet router + H4C5 stable bridge

This keeps the original Render Tailscale subnet router and adds a tailnet-only TCP bridge for H4C5.

Flow:

```
H4C5 gateway on admin PC (HMAC signer)
  -> Tailscale MagicDNS name of this router :19000
  -> Tailscale TCP Serve
  -> socat on 127.0.0.1:19000
  -> h4c5-panel-private:3000 (Render stable internal hostname)
```

The private service's 10.x instance IP may change on deploy. This bridge never stores that IP; Render DNS resolves the current instance.

## Important security property

`PRIVATE_GATEWAY_KEY` does NOT belong in this router. The HMAC signer remains on the administrative PC and the H4C5 backend still verifies it.

## Variables

- `TAILSCALE_AUTHKEY`: existing Tailscale auth key
- `TAILSCALE_VERSION`: default 1.96.4
- `ADVERTISE_ROUTES`: default 10.0.0.0/8
- `H4C5_TARGET_HOST`: default h4c5-panel-private
- `H4C5_TARGET_PORT`: default 3000
- `H4C5_BRIDGE_PORT`: default 19000

After deploy, check logs for:

`H4C5 stable bridge ready: tailnet TCP 19000 -> h4c5-panel-private:3000`

Then on the admin PC point `H4C5_PRIVATE_TARGET` to the router's stable MagicDNS FQDN on port 19000.
