# syntax=docker/dockerfile:1
#
# Omnigent for the Railway template. This is the official, CI-built upstream server image pinned by digest — the
# web UI bundle is gitignored upstream, so a source build cannot reproduce it; the only correct source is the
# published image. The application is unmodified: all configuration (database, auth, admin bootstrap, port) is
# supplied through environment variables by the template. Not affiliated with the Omnigent project.
#
# The image's own entrypoint (`python /app/entrypoint.py`) resolves HOST/PORT (coercing Railway's IPv6 wildcard
# to 0.0.0.0), runs database migrations, seeds the first admin from OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD, and
# starts uvicorn.
ARG OMNIGENT_IMAGE=ghcr.io/omnigent-ai/omnigent-server:v0.1.0@sha256:a3626af20e6ebbb5f9f8792528d9f6c68cf6807e5fe219bb93bbb5831d2e5ac9

FROM ${OMNIGENT_IMAGE}
ARG WRAPPER_VERSION=0.0.0-dev
ARG VCS_REF=unknown
ARG BUILD_DATE=1970-01-01T00:00:00Z

LABEL org.opencontainers.image.title="omnigent-railway" \
      org.opencontainers.image.description="Omnigent server for the Railway template: the official image, pinned by digest. Not affiliated with the Omnigent project." \
      org.opencontainers.image.source="https://github.com/youssefsiam38/omnigent-railway" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.version="${WRAPPER_VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}"
