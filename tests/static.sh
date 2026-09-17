#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016
# Static validation: syntax, shellcheck, compose, image pins and security defaults. No Docker build.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
cd "$REPO_ROOT"
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

section "syntax"
for f in tests/*.sh; do
  if bash -n "$f" 2>/dev/null; then pass "parses: $f"; else fail "syntax error: $f"; fi
done

section "shellcheck"
if command -v shellcheck >/dev/null; then
  if shellcheck -x -s bash tests/*.sh; then pass "shellcheck tests"; else fail "shellcheck tests"; fi
else
  echo "  SKIP  shellcheck not installed"
fi

section "compose"
if docker compose -f compose.yaml config -q; then pass "compose config"; else fail "compose config"; fi
cfg=$(docker compose -f compose.yaml config --format json)
assert_eq "two services" "db omnigent" "$(jq -r '[.services | keys[]] | sort | join(" ")' <<<"$cfg")"
assert_eq "only omnigent publishes a port" "omnigent" "$(jq -r '[.services | to_entries[] | select(.value.ports) | .key] | join(" ")' <<<"$cfg")"
assert_eq "the port binds to loopback" "127.0.0.1" "$(jq -r '[.services.omnigent.ports[]? | .host_ip] | join(" ")' <<<"$cfg")"
assert_eq "the omnigent data volume is mounted" "/data" "$(jq -r '[.services.omnigent.volumes[]? | .target] | join(" ")' <<<"$cfg")"
assert_eq "the database volume is mounted" "/var/lib/postgresql" "$(jq -r '[.services.db.volumes[]? | .target] | join(" ")' <<<"$cfg")"
assert_contains "postgres is pinned by tag and digest" '@sha256:[0-9a-f]\{64\}$' "$(jq -r '.services.db.image' <<<"$cfg")"
assert_eq "the accounts auth provider is selected" "accounts" "$(jq -r '.services.omnigent.environment.OMNIGENT_AUTH_PROVIDER' <<<"$cfg")"
assert_eq "self-service open registration is off" "0" "$(jq -r '.services.omnigent.environment.OMNIGENT_ACCOUNTS_AUTO_OPEN' <<<"$cfg")"
assert_contains "the DB connection string is set" '^postgres://' "$(jq -r '.services.omnigent.environment.DATABASE_URL' <<<"$cfg")"

section "image pins"
df=images/omnigent/Dockerfile
assert_contains "omnigent base pinned by digest" '^ARG OMNIGENT_IMAGE=.*@sha256:[0-9a-f]\{64\}$' "$(grep '^ARG OMNIGENT_IMAGE=' "$df")"

section "bootstrap security"
# The admin race (POST /auth/setup, unauthenticated while no password account exists) is closed by pre-seeding the
# admin from OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD; the compose value is an obvious local-only placeholder.
assert_contains "an initial admin password is provided" 'OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD' "$cfg"
assert_contains "the compose admin password is a placeholder" 'local-test-only' "$(jq -r '.services.omnigent.environment.OMNIGENT_ACCOUNTS_INIT_ADMIN_PASSWORD' <<<"$cfg")"

section "secrets hygiene"
mapfile -t tracked < <(git ls-files 2>/dev/null | grep . || find . -type f -not -path './.git/*' -not -path './test-output/*')
if [ "${#tracked[@]}" -gt 0 ] && grep -lE '(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----)' "${tracked[@]}" 2>/dev/null; then
  fail "a credential-shaped string is in the repository"
else
  pass "no credential-shaped strings in ${#tracked[@]} files"
fi

summary
