# Upstream and pinned versions

This template packages **Omnigent** (the server / control plane) with a bundled **PostgreSQL**. Both run from
official images, pinned by digest.

## Omnigent

- Project: https://github.com/omnigent-ai/omnigent
- Licence: Apache-2.0 (`licenses/OMNIGENT-LICENSE`, `licenses/OMNIGENT-NOTICE`)
- Official image: `ghcr.io/omnigent-ai/omnigent-server` (CI-built; it ships the web UI bundle that a source build
  cannot reproduce — this is why the template uses the published image, not a rebuild)
- Pinned: `ghcr.io/omnigent-ai/omnigent-server:v0.1.0`
  - digest `sha256:a3626af20e6ebbb5f9f8792528d9f6c68cf6807e5fe219bb93bbb5831d2e5ac9`
- The wrapper image (`images/omnigent/Dockerfile`) is `FROM` that digest and adds only labels. The application,
  its entrypoint (`python /app/entrypoint.py`), migrations and admin bootstrap are unchanged.

## PostgreSQL

- Image: `postgres` (official)
- Pinned: `postgres:18.2-alpine3.23`
  - digest `sha256:035b9ab53cfa147d7202b61f5f7782b939ae815b7d6bc81c96b7b42ff1fca950`
- Omnigent needs only the standard `pg_trgm` contrib extension (it runs `CREATE EXTENSION IF NOT EXISTS pg_trgm`
  itself as the database superuser). No pgvector or other extensions.

## Refreshing a digest

```bash
docker buildx imagetools inspect ghcr.io/omnigent-ai/omnigent-server:<tag> --format '{{json .Manifest}}' | jq -r .digest
docker buildx imagetools inspect postgres:<tag>                           --format '{{json .Manifest}}' | jq -r .digest
```

Update the pins here, in `images/omnigent/Dockerfile` (`ARG OMNIGENT_IMAGE`), in `compose.yaml` (postgres image),
and in `_audit/spec_omnigent.py`, then bump the wrapper tag and re-run the tests. See `MAINTENANCE.md`.
