#!/usr/bin/env bash
# shellcheck disable=SC2015
# Persistence: accounts live in PostgreSQL (the pg volume); artifacts and the admin-credentials/cookie state on
# the omnigent /data volume. Take the stack down keeping volumes, bring it back, and confirm the admin still logs
# in and the setup race stays closed (proving the accounts DB survived). Standalone: brings the stack up itself.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'compose logs --no-color --tail 100 || true; compose down -v --remove-orphans >/dev/null 2>&1 || true; rm -rf "$TEST_TMP"' EXIT

ADMIN_USER=${OMNIGENT_TEST_ADMIN_USERNAME:-admin}
ADMIN_PW=${OMNIGENT_TEST_ADMIN_PASSWORD:-local-test-only-admin-password}

section "bring the stack up"
compose up -d --build >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/health" 200 240 || die "server never became healthy"

section "before restart"
jar="$TEST_TMP/jar1"
login_cookiejar "$ADMIN_USER" "$ADMIN_PW" "$jar" && pass "the admin logs in before the restart" || die "admin login failed before restart"

section "full restart (volumes preserved)"
compose down >/dev/null 2>&1
compose up -d >/dev/null 2>&1 || die "compose up failed"
wait_for_code "$APP_URL/health" 200 240 && pass "healthy again after restart" || die "not healthy after restart"

section "after restart"
assert_eq "the setup race is still closed (accounts table persisted)" "409" \
  "$(http_code -X POST "$APP_URL/auth/setup" -H 'Content-Type: application/json' --data '{"username":"x","password":"x-pw-123456"}')"
jar2="$TEST_TMP/jar2"
login_cookiejar "$ADMIN_USER" "$ADMIN_PW" "$jar2" && pass "the admin from before still logs in" || fail "admin login failed after restart"

summary
