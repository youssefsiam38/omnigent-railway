# Marketplace audit

A record of the diligence behind publishing this template.

## Identity

- Template: **Omnigent** (AI agent meta-harness — the server / control plane).
- Upstream: [omnigent-ai/omnigent](https://github.com/omnigent-ai/omnigent), Apache-2.0, active (~10k★). Upstream
  ships a `railway.toml` and lists a published Railway template as a TODO — Railway deployment is intended.
- Database: official `postgres` image.

## Licence

- Omnigent is Apache-2.0 (`licenses/OMNIGENT-LICENSE` + `OMNIGENT-NOTICE`); redistribution as a template is
  permitted. The application is used unmodified from the official image; the wrapper only adds labels.
- PostgreSQL is under the permissive PostgreSQL License. See `THIRD_PARTY_NOTICES.md`.

## Security review

- **First-visitor race closed.** The `accounts` provider's `POST /auth/setup` is unauthenticated until a password
  account exists; the template pre-seeds the admin from a generated password, so setup returns `409` before the URL
  is public (verified in smoke + persistence + live tests).
- **Registration invite-only** (`OMNIGENT_ACCOUNTS_AUTO_OPEN=0`); walk-up register is refused.
- **Generated secrets.** Admin password (alnum24) and cookie secret (hex64) are generated per deploy; the public
  base URL is wired to the Railway domain. No secret is baked into an image or committed; the static test greps for
  credential shapes and the tests never print secrets.
- **Private database.** PostgreSQL has no public domain; reachable only over the private network.
- **Reproducible.** Both images pinned by digest.
- **Compute boundary disclosed.** Agents run on a connected backend (a machine or sandbox provider), not in the
  server container; this is documented in README/SECURITY/OVERVIEW so operators understand the trust boundary.

## Reproducibility & tests

- `tests/static.sh` (20 checks): syntax, shellcheck, compose shape, digest pins, auth posture, secret scan.
- `tests/smoke.sh` (9 checks): health, closed setup race, seeded-admin login, wrong-password + walk-up-register
  refusal, authenticated `/v1/sessions`.
- `tests/persistence.sh` (4 checks): the admin and accounts survive a full restart with volumes kept.
- `tests/railway-smoke.sh`: the same flows over HTTPS against the deployed template.
- CI runs static + build + smoke + persistence on every push; the publish workflow re-tests the candidate image
  before pushing it to GHCR.

## Scope note

This template deploys a complete, self-contained **control plane** (server + PostgreSQL). Running agents requires
connecting a compute backend — the user's own machine (free) or a sandbox provider. That is a documented,
bring-your-own-compute step, not a hidden dependency on a paid platform: the deployment is fully functional and
useful as the orchestration/collaboration hub on its own.

## Verdict

Shippable. A self-contained, reproducible, admin-seeded Omnigent control plane with a bundled private PostgreSQL,
verified end-to-end on a live Railway deployment.
