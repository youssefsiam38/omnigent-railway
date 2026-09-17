# Maintenance

## Releasing a new version

1. **Bump the upstream pins.** Get the new digests (see `UPSTREAM.md`) and update:
   - `images/omnigent/Dockerfile` — `ARG OMNIGENT_IMAGE=...@sha256:...`
   - `compose.yaml` — the `postgres` image pin
   - `UPSTREAM.md` and `_audit/spec_omnigent.py`
2. **Run the tests locally.**
   ```bash
   tests/static.sh
   tests/smoke.sh
   tests/persistence.sh
   ```
3. **Tag and push.** `git tag vX.Y.Z && git push --tags`. The `publish-image` workflow builds the wrapper, runs
   the tests against the candidate, and pushes `:X.Y.Z`, `:X.Y` and `:latest` to GHCR.
4. **Update the template** if the pinned image tag changed: set the omnigent service's image to the new tag and
   re-run the clean-room deploy + `tests/railway-smoke.sh` before publishing.

## Rebuilding the Railway template from scratch

The exact configuration is in `RAILWAY_TEMPLATE.md`. The generator spec is `_audit/spec_omnigent.py`; the kit in
`_audit/` (`tplkit.py`) builds a skeleton project, patches the template, and runs a clean-room deploy. Volumes,
domains and health checks are only set by `skeleton()`, so a change to any of those requires rebuilding from a
skeleton (not just patching).

## Gotchas worth remembering

- **`PORT` must equal the listen port (8000) and the domain target port.** Railway routes the public edge and the
  health check to `PORT`; a mismatch is the classic "Application failed to respond". The template fixes all three
  at 8000.
- **The admin race.** `POST /auth/setup` is unauthenticated until a password account exists; the template pre-seeds
  the admin via `OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD` so it is closed before the URL is public.
- **HOST.** Railway injects `HOST=[::]`; the image entrypoint coerces it to `0.0.0.0`. The template also sets
  `HOST=0.0.0.0` explicitly.
- **Postgres data dir.** PostgreSQL 18's `PGDATA` is `/var/lib/postgresql/18/docker`; the volume mounts the parent
  `/var/lib/postgresql`, which covers it.
- **The image is not rebuildable from source.** The web UI bundle is gitignored upstream, so always base the
  wrapper on the published `omnigent-server` image, never a source build.
- **Compute is separate.** Agents run on a connected backend (a machine or a sandbox provider), not in the server
  container. The template deploys the control plane; document connecting a backend, don't try to run agents in-box.
