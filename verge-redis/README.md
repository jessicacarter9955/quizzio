# VERGE Market Pub/Sub Backend (Redis/Valkey)

This is a dedicated Node.js WebSocket bridge for VERGE market-data updates.

## Transport
Twelve Data WebSocket -> Supabase Edge worker `verge-market-run` -> verified quotes
stored in Supabase -> Node `verge-redis/server.mjs` polls the verified feed every 15s
-> Redis `PUBLISH verge:market:quotes` -> authenticated-origin browser WebSocket
clients at `/ws/quotes`.

Financial persistence (wallets, positions, orders, lessons, groups) remains exclusively
in Supabase Postgres. Redis is ephemeral cache/pub-sub, never the source of truth.

## Required environment
- `REDIS_URL`: secret Redis/Valkey TLS URI, never committed.
- `PORT`: Render-assigned HTTP port.
- `ALLOWED_ORIGIN`: `https://quizlab-responsive-web.onrender.com`.
- `QUOTE_SOURCE_URL`: defaults to public `verge-market-api/v1/quotes`.
- `POLL_INTERVAL_MS`: defaults to 15000; minimum 12000.

## Health and readiness
`GET /health` returns HTTP 503 until Redis publisher and subscriber are ready.
The websocket endpoint likewise rejects connections until Redis is ready.
No fake realtime status is returned when credentials are missing.
Quote timestamps originate in Twelve Data; checking later does not make stale prices current.

## Hosting blocker (2026-11-13)
A Free Render Key Value instance was requested. Render rejected creation because
the workspace is at the Hobby plan limit of 25 services. An existing suspended
free `chatwoot-redis` instance is not active and belongs to another project.
This code is committed but **not deployed as an operational Redis service**.

Deployment can be completed after free capacity is available, or by connecting a
free Upstash Redis instance (subject to Upstash free-tier command/bandwidth limits).
The target Node server itself must also be hosted somewhere that accepts continuous
WebSocket connections; suspended Render free services do not guarantee continuity.

## Security
Redis credentials stay server side. Browser clients never receive the Redis URI.
The WS server only accepts the configured website Origin.
TLS should be used for remote Redis and WebSockets; do not expose Redis directly.
Production hardening should include quotas, metrics, a health probe,
redundancy, and eventual tenant-specific authorization where appropriate.
