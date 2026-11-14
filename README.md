# xray-cloady-node

Minimal Xray node (VLESS + WebSocket) for [Cloady](https://cloady.com) free tier.
TLS is terminated at Cloady's edge — Xray listens for plain WebSocket inside
the container. No credentials are stored in this repo.

## How the port works (Cloady docs)

- Cloady builds a repo in this order: compose file → `Dockerfile` → Railpack.
- `docker-compose.yml` publishes port **3000** under `ports:` — 3000 is a web
  port, so the app gets an `https://<name>-<code>-<workspace>.cloady.io` URL.
- Without a compose file Cloady would still serve the app on port 3000 unless
  the `PORT` variable names another port. The entrypoint honours `PORT`
  (default `3000`), so either path works.
- CPU/RAM are deliberately undeclared: Cloady's defaults (0.5 vCPU / 1 GB)
  are exactly the free tier (Nano size).

## Deploy (dashboard, no CLI needed)

1. Sign in to Cloady, create a workspace (first workspace is the free one).
2. **New application → GitHub repository** → pick this repo
   (`daring-falcon-58/xray-cloady-node`).
3. **Region:** `use1` (US East) or `usw1` (US West). Environment: production.
4. **Environment step (before first deploy):** add a variable
   - `UUID` = your VLESS client id, marked **secret**. (Generate a fresh
     UUID v4, e.g. `cat /proc/sys/kernel/random/uuid`. Keep it private —
     anyone with it can use the node.)
   - `PORT` is optional; leave unset (defaults to `3000`).
5. **Deploy.** Cloady builds the image, then waits until the service accepts
   connections on port 3000. The app goes live at
   `https://<name>-<code>-<workspace>.cloady.io`.
6. If you skipped the `UUID` variable, the entrypoint generates one and prints
   it in the deploy logs — read it there and use it in the client link.

## Verify it is live

```sh
curl -i https://<your-app>.cloady.io/vless
# expect: HTTP/2 400 (plain GET is not a WebSocket handshake — 400 proves
# the Xray listener is answering through Cloady's TLS edge)
```

## Little Rocket (Shadowrocket) import link

Replace `HOST` with the assigned `*.cloady.io` hostname and `UUID` with the
value you set in step 4:

```
vless://UUID@HOST:443?encryption=none&security=tls&sni=HOST&type=ws&path=%2Fvless#xray-cloady
```

## Free-tier notes / caveats

- Free tier = one workspace per account while its apps fit 0.5 vCPU / 1 GB /
  5 GB; includes 10 GB outbound traffic and 1M HTTP requests per month.
  No card is required for the free tier.
- Cloady docs describe **two** free mechanisms: the free tier (no preset end
  date) and a one-month free trial for an account's first small app in select
  regions. If your app lands on the trial, Cloady emails 3 days before it
  ends; without a card it then stops (data kept) and restarting needs a card.
  Never add a card for this node — if it stops, the node is done.
- Apps idle for 7 days may be suspended — use the node at least weekly.
- There is no dedicated inbound IPv4; the node is reached only via the
  `*.cloady.io` hostname over 443 (fine for this WS setup).
- Xray v26.11.9 logs a warning that the WebSocket transport is deprecated in
  favour of XHTTP, but WS still works; WS is what Little Rocket expects here.
