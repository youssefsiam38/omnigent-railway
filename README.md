# Omnigent on Railway

A one-click [Railway](https://railway.com) template that runs the [Omnigent](https://github.com/omnigent-ai/omnigent)
server — an open-source **AI agent meta-harness**: orchestrate Claude Code, Codex, Cursor and custom agents from a
shared web app, swap harnesses without rewriting, enforce policies, and collaborate in real time. This template
deploys the **control plane** (the server + PostgreSQL) with your admin account seeded and secrets generated.

This is a community-maintained template and is not affiliated with the Omnigent project.

- **Template image:** `ghcr.io/youssefsiam38/omnigent-railway` (the official Omnigent server image, pinned by digest)
- **Upstream:** Omnigent (Apache-2.0) + PostgreSQL — see [UPSTREAM.md](UPSTREAM.md)

## What you get

- Two services: **omnigent** (public HTTPS web app + API) and **db** (private PostgreSQL, on its own volume).
- Built-in **accounts** auth (multi-user, no external IdP). Your admin is **seeded at first boot** from a generated
  password, which closes the "first visitor claims the instance" race on the public URL.
- A generated cookie secret; the public base URL is wired to your Railway domain.
- A persistent `/data` volume for artifacts and server state.

## Deploy

1. Click **Deploy on Railway** and wait for both services to go healthy.
2. Open the **omnigent** service → **Variables** and copy `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` (username `admin`).
3. Open the public domain and sign in. Invite teammates from **Members**.

## Running agents (important)

Omnigent is a **meta-harness**: the server coordinates agent runs, but the agents execute on a **compute backend
you connect**, not inside this server. After deploying, connect one of:

- **Your own machine** — install the Omnigent harness CLI on a laptop/VM and connect it to the server (free; your
  own compute).
- **A sandbox provider** — E2B, Modal, microsandbox, and others are supported (see upstream `deploy/`); most are
  paid third-party services.

The server itself does not run a privileged in-container sandbox on Railway. This is by design: the deployment is
the collaboration + orchestration hub, and execution is brought to it. See upstream's docs for connecting hosts.

## Switching to your own IdP (OIDC)

The template defaults to built-in accounts. To use GitHub/Google/Okta instead, set `OMNIGENT_AUTH_PROVIDER=oidc`
and the `OMNIGENT_OIDC_*` variables on the omnigent service (see [SECURITY.md](SECURITY.md) and upstream's Railway
guide).

## Security

- The admin password and the cookie secret are generated per deploy; treat the admin password like any password
  and rotate it by changing the variable.
- PostgreSQL has no public domain — it is reachable only by the omnigent service over Railway's private network.
- TLS is terminated at Railway's edge. See [SECURITY.md](SECURITY.md).

## Repository layout

| Path | What |
|---|---|
| `images/omnigent/Dockerfile` | The wrapper image: upstream server pinned by digest |
| `compose.yaml` | Local test topology mirroring the Railway service graph |
| `tests/` | Static, smoke, persistence, and live (HTTPS) tests |
| `marketplace/OVERVIEW.md` | The marketplace overview shown on the template page |
| `RAILWAY_TEMPLATE.md` | The exact published template configuration |
| `UPSTREAM.md` · `SECURITY.md` · `ARCHITECTURE.md` · `MAINTENANCE.md` | Reference docs |

## Local development

```bash
docker compose up --build     # bring up db + omnigent
tests/smoke.sh                # health, seeded admin, closed setup, authed API
tests/persistence.sh          # the admin + accounts survive a restart
```

## Licence

The template's own files are MIT (`LICENSE`). Omnigent and PostgreSQL keep their own licences; see
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
