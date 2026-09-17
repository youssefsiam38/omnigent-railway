# Railway template configuration

The template's exact configuration. Reproduce it from this file if it ever has to be rebuilt.

| | |
|---|---|
| Name | Omnigent |
| Code | `omnigent` |
| Template id | `0465687c-c6c8-4b6a-b15e-7447c1e7e747` |
| Deploy URL | https://railway.com/deploy/omnigent |
| Category | AI/ML |
| Card description | Self-hosted AI agent meta-harness (Claude Code, Codex); admin seeded. |
| Icon | `assets/icon.png` |
| Overview markdown | `marketplace/OVERVIEW.md` (Railway enforces its section headings) |

Generated values use Railway's `secret()` function: `hexN` is `${{secret(N, "abcdef0123456789")}}` and `alnumN` is
`${{secret(N, "a-zA-Z0-9")}}` spelled out. Alphanumeric passwords are used wherever a value is embedded in a
connection URL, so nothing needs percent-encoding. Images are referenced by tag, because the template generator
rejects digests; `UPSTREAM.md` records the digests.

## Services

### `db`

| Field | Value |
|---|---|
| Source | `postgres:18.2-alpine3.23` |
| Public domain | none |
| Volume | `/var/lib/postgresql` |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `POSTGRES_USER` | `omnigent` |
| `POSTGRES_DB` | `omnigent` |
| `POSTGRES_PASSWORD` | generated, alnum48 |

### `omnigent`

| Field | Value |
|---|---|
| Source | `ghcr.io/youssefsiam38/omnigent-railway:1.0.0` |
| Public domain | target port 8000 |
| Volume | `/data` |
| Healthcheck | `/health`, timeout from `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` |
| Restart policy | on failure, 10 retries |

| Variable | Value |
|---|---|
| `DATABASE_URL` | `postgres://omnigent:${{db.POSTGRES_PASSWORD}}@${{db.RAILWAY_PRIVATE_DOMAIN}}:5432/omnigent` |
| `OMNIGENT_AUTH_PROVIDER` | `accounts` |
| `OMNIGENT_ACCOUNTS_AUTO_OPEN` | `0` |
| `OMNIGENT_ACCOUNTS_INIT_ADMIN_USERNAME` | `admin` |
| `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` | generated, alnum24 |
| `OMNIGENT_ACCOUNTS_COOKIE_SECRET` | generated, hex64 |
| `OMNIGENT_ACCOUNTS_BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` |
| `ARTIFACT_DIR` | `/data/artifacts` |
| `OMNIGENT_ADMIN_CREDENTIALS_PATH` | `/data/admin-credentials` |
| `HOST` | `0.0.0.0` |
| `PORT` | `8000` |
| `RAILWAY_HEALTHCHECK_TIMEOUT_SEC` | `300` |
| `OMNIGENT_FEATURES` | optional, unset |

## Notes

- **`PORT` must equal the server's listen port (8000) and the domain target port.** Railway routes both the public
  edge and the health check to `PORT`; a mismatch is the classic "Application failed to respond". The template
  fixes all three at 8000. `HOST` is set to `0.0.0.0` (the image entrypoint also coerces Railway's `[::]`).
- **The admin race is closed by pre-seeding.** `POST /auth/setup` is unauthenticated until a password account
  exists; the template seeds the admin from the generated `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` (username
  `admin`) on first boot, and keeps self-service registration off (`OMNIGENT_ACCOUNTS_AUTO_OPEN=0`).
- The image runs as root, so no `RAILWAY_RUN_UID` is needed for the `/data` volume. PostgreSQL 18's data dir is
  `/var/lib/postgresql/18/docker`; the volume mounts the parent `/var/lib/postgresql`.
- The upstream image is used unmodified (the web UI bundle is gitignored upstream, so it can't be rebuilt from
  source); the wrapper only pins the digest and adds labels.
- **Agents run on a connected compute backend** (your own machine or a sandbox provider), not inside the server
  container. The template deploys the control plane; connecting a backend is a documented user step.
