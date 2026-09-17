# Security

## The first-visitor race, closed

Omnigent's `accounts` provider exposes `POST /auth/setup` **unauthenticated while no password-bearing account
exists** — so a public instance reachable before you finish the create-admin form can be claimed by the first
visitor. This template **pre-seeds the admin from a generated `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` on first
boot**, so `/auth/setup` is already closed (returns `409`) by the time the URL is live. Verified in the smoke,
persistence and live tests.

## What the template does

- **Seeded admin, generated password.** Username `admin`, password generated (24 alphanumerics). Copy it from the
  service variables to sign in.
- **Registration is invite-only.** `OMNIGENT_ACCOUNTS_AUTO_OPEN=0`; walk-up `POST /auth/register` is refused.
  Add teammates via **Members** (invites).
- **Generated cookie secret.** `OMNIGENT_ACCOUNTS_COOKIE_SECRET` is a generated 64-hex-char value, so sessions are
  signed with a per-deploy secret (not a shared or disk-minted default).
- **Correct public base URL.** `OMNIGENT_ACCOUNTS_BASE_URL` is wired to the Railway public domain so invite/magic
  links resolve to the right host.
- **Private database.** PostgreSQL has no public domain; it is reachable only by the omnigent service over
  Railway's private network.
- **TLS at the edge.** Railway terminates HTTPS; the internal hop is plaintext inside the private network.
- **Pinned images.** Both images are pinned by digest (see `UPSTREAM.md`).
- **Secret hygiene.** No secret is baked into an image layer or committed; the tests never print secrets and read
  the admin password from a mode-restricted file over HTTPS. A static check greps the tree for credential shapes.

## What you should do

- **Copy and guard the admin password** right after deploying; rotate it by changing the variable (note: changing
  `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` only affects the *initial* seed — change an existing admin's password from
  the app).
- **Restrict OIDC domains.** If you switch to `OMNIGENT_AUTH_PROVIDER=oidc` with Google, always set
  `OMNIGENT_OIDC_ALLOWED_DOMAINS`, or any Google account can log in.
- **Understand the compute model.** Agents run on a backend you connect (your machine or a sandbox provider), which
  has its own trust boundary. Only connect backends you control, and review upstream's sandboxing docs before
  pointing agents at sensitive resources.
- **Back up the volumes** (accounts DB + artifacts) with Railway's volume backups.

## Reporting

For issues in Omnigent or PostgreSQL themselves, report upstream. For issues specific to this template's packaging,
open an issue on the template repository.
