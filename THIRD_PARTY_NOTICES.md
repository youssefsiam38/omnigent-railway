# Third-party notices

This template packages and runs the following third-party software. Each keeps its own licence; the template's own
files are MIT (see `LICENSE`).

## Omnigent

- Source: https://github.com/omnigent-ai/omnigent
- Licence: Apache-2.0 — full text in `licenses/OMNIGENT-LICENSE`, attribution in `licenses/OMNIGENT-NOTICE`
- Used unmodified from the official image `ghcr.io/omnigent-ai/omnigent-server` (pinned by digest in `UPSTREAM.md`).
  The wrapper image only adds OCI labels; it does not alter the application, its entrypoint, or its bundled web UI.

## PostgreSQL

- Source: https://www.postgresql.org — official Docker image `postgres`
- Licence: PostgreSQL License (permissive, BSD/MIT-style)
- Used unmodified from the official image (pinned by digest in `UPSTREAM.md`).

---

"Omnigent" is the mark of its project. This template is community-maintained and is not affiliated with, or
endorsed by, the Omnigent project.
