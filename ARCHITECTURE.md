# Architecture

## Service graph

```
                 Railway edge (HTTPS, TLS)
                          │
                          ▼
        ┌──────────────────────────────────┐
        │  omnigent  (public domain :8000)  │   volume: /data  (artifacts, admin-credentials, cookie state)
        │  FastAPI/uvicorn web app + API    │
        │  - GET  /health   (no auth)       │
        │  - POST /auth/*   (accounts auth) │
        │  - /v1/*          (session JWT)   │
        └───────────────┬──────────────────┘
                        │  Railway private network
                        ▼
        ┌──────────────────────────────────┐
        │  db  (no public domain :5432)     │   volume: /var/lib/postgresql
        │  PostgreSQL (accounts, sessions)  │
        └──────────────────────────────────┘

        Agent execution → a compute backend you connect (your machine, or a
        sandbox provider). Not run inside the omnigent container on Railway.
```

## The omnigent service

- Image: the official `ghcr.io/omnigent-ai/omnigent-server` pinned by digest. The wrapper adds only labels.
- **Entrypoint:** `python /app/entrypoint.py` resolves HOST/PORT (coercing Railway's IPv6 wildcard `[::]` to
  `0.0.0.0`), runs Alembic migrations, seeds the first admin, then starts uvicorn.
- **Port:** listens on `PORT` (default 8000). The template fixes `PORT=8000`, sets the public domain's target port
  to `8000`, and the health check path to `/health` — all aligned so Railway routes traffic and health checks to
  the right port. (A mismatch here is the classic "Application failed to respond".)
- **Auth:** `OMNIGENT_AUTH_PROVIDER=accounts` (multi-user, no IdP). The admin is seeded from
  `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` on first boot, which closes the unauthenticated `POST /auth/setup` race.
  `OMNIGENT_ACCOUNTS_AUTO_OPEN=0` keeps self-service registration invite-only. The cookie secret
  (`OMNIGENT_ACCOUNTS_COOKIE_SECRET`) and base URL (`OMNIGENT_ACCOUNTS_BASE_URL`) are set from generated/Railway
  values so invite and magic links resolve to the public domain.
- **Volume:** `/data` holds artifacts (`ARTIFACT_DIR=/data/artifacts`) and admin-credentials/cookie state
  (`OMNIGENT_ADMIN_CREDENTIALS_PATH=/data/admin-credentials`). The image runs as root, so no `RAILWAY_RUN_UID` is
  needed for the volume.

## The db service

- Image: the official `postgres:18.2-alpine3.23` pinned by digest, run as-is.
- Omnigent creates the `pg_trgm` extension it needs on first boot (superuser). No pgvector.
- **Volume:** `/var/lib/postgresql` (PostgreSQL 18's data dir is `/var/lib/postgresql/18/docker`, under this path).
- omnigent reaches it via `DATABASE_URL=postgres://omnigent:<pw>@${db.RAILWAY_PRIVATE_DOMAIN}:5432/omnigent`
  (the app normalizes the scheme to `postgresql+psycopg`).

## Compute / agent execution

Omnigent is a meta-harness: the deployed server is the orchestration and collaboration plane. Agent runs execute
on a connected compute backend — a machine running the Omnigent harness CLI, or a sandbox provider (E2B, Modal,
microsandbox, …). The server intentionally does not run a privileged in-container sandbox on Railway (Railway does
not offer privileged containers or a host Docker socket). See upstream `deploy/` for backend options.
