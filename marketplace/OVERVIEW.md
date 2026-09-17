# Deploy and Host Omnigent on Railway

Omnigent is an open-source AI agent framework and meta-harness: orchestrate Claude Code, Codex, Cursor and custom
agents from one shared web app, swap harnesses without rewriting, enforce policies, and collaborate in real time
from any device. This template deploys the Omnigent **control plane** — the server plus PostgreSQL — with your
admin account seeded and secrets generated. It is a community-maintained template and is not affiliated with the
Omnigent project.

## About Hosting Omnigent

Omnigent's server is a FastAPI/uvicorn app backed by PostgreSQL. Its built-in `accounts` auth exposes an
unauthenticated first-run setup endpoint, so a public instance reached before you create the admin can be claimed
by whoever opens it first, and it needs a database URL, a signed-cookie secret and the correct public base URL
wired up to work over HTTPS.

This template runs Omnigent on Railway with a bundled private PostgreSQL, seeds your administrator from a generated
password at first boot (so the setup endpoint is already closed when the URL goes live), keeps self-service
registration invite-only, generates the cookie secret, and wires the database, the public base URL, the port and
the health check. Agents execute on a compute backend you connect (your own machine, or a sandbox provider) — the
deployment is the orchestration and collaboration hub. Both services run from official images, pinned by digest.

## Common Use Cases

- A shared, self-hosted hub for a team to run and watch AI coding agents (Claude Code, Codex, and others).
- A policy-and-collaboration layer in front of multiple agent harnesses, swappable without rewriting workflows.
- A private, multi-user Omnigent instance where accounts and history live in your own database.

## Dependencies for Omnigent Hosting

- Nothing external to stand up the server — PostgreSQL is bundled.
- To run agents, connect a compute backend: your own machine (free) or a sandbox provider (e.g. E2B, Modal).

### Deployment Dependencies

- Omnigent: https://github.com/omnigent-ai/omnigent (Apache-2.0)
- PostgreSQL: https://www.postgresql.org (official Docker image)
- Template repository, image and tests: https://github.com/youssefsiam38/omnigent-railway

### Implementation Details

Omnigent runs upstream's official server image, pinned by digest (a source build can't reproduce the bundled web
UI, so the published image is used unmodified). The `accounts` auth provider is selected; the admin is seeded from
a generated `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` (username `admin`) at first boot, closing the unauthenticated
`/auth/setup` race; self-service registration is off. A generated cookie secret and the Railway public base URL are
set, the database URL points at the bundled PostgreSQL over the private network, and a `/data` volume persists
artifacts and server state. PostgreSQL runs from its official image with no public domain, on its own volume.

Tested in CI and on a live deployment of this template: the server is healthy, the setup race is closed, the seeded
admin logs in while a wrong password and walk-up registration are refused, an authenticated API call works, and the
admin and accounts survive a redeploy.

After deploying, copy `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` from the omnigent service's variables and sign in at
the app's domain (username `admin`). To run agents, connect a compute backend as described in the repository.

## Why Deploy Omnigent on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you
don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Omnigent on Railway, you are one step closer to supporting a complete full-stack application with
minimal burden. Host your servers, databases, AI agents, and more on Railway.
