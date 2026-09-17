#!/usr/bin/env bash
# shellcheck disable=SC2015
# Smoke test: build+run the stack (or reuse a running one), then exercise the Omnigent server the way a browser
# and API client do — liveness, the seeded admin, the closed setup race, and an authenticated API call.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"

ADMIN_USER=${OMNIGENT_TEST_ADMIN_USERNAME:-admin}
ADMIN_PW=${OMNIGENT_TEST_ADMIN_PASSWORD:-local-test-only-admin-password}

STARTED=0
if [ "${OMNIGENT_REUSE_STACK:-0}" != "1" ]; then
  section "bring the stack up"
  compose up -d --build >/dev/null 2>&1 || die "compose up failed"
  STARTED=1
  trap 'compose logs --no-color --tail 100 || true; [ "$STARTED" = 1 ] && compose down -v --remove-orphans >/dev/null 2>&1 || true; rm -rf "$TEST_TMP"' EXIT
else
  trap 'rm -rf "$TEST_TMP"' EXIT
fi

section "liveness"
wait_for_code "$APP_URL/health" 200 240 && pass "/health returns 200" || die "server never became healthy"
assert_contains "/health reports ok" '"status":"ok"' "$(curl -s --max-time 10 "$APP_URL/health")"

section "the setup race is closed (admin pre-seeded)"
assert_eq "POST /auth/setup is refused once an admin exists" "409" \
  "$(http_code -X POST "$APP_URL/auth/setup" -H 'Content-Type: application/json' --data '{"username":"intruder","password":"intruder-pw-123456"}')"

section "the seeded admin can log in"
bad=$(http_code -X POST "$APP_URL/auth/login" -H 'Content-Type: application/json' --data '{"username":"admin","password":"definitely-wrong"}')
assert_eq "a wrong password is rejected" "401" "$bad"
jar="$TEST_TMP/jar"
login_cookiejar "$ADMIN_USER" "$ADMIN_PW" "$jar" && pass "the seeded admin logs in" || fail "admin login failed"

section "public self-registration is not open"
reg=$(http_code -X POST "$APP_URL/auth/register" -H 'Content-Type: application/json' --data '{"username":"walkup","password":"walkup-pw-123456","email":"w@example.test"}')
[ "$reg" != "200" ] && pass "walk-up registration is refused ($reg)" || fail "walk-up registration succeeded"

section "an authenticated API call works"
assert_eq "GET /v1/sessions requires authentication" "401" "$(http_code "$APP_URL/v1/sessions")"
assert_eq "GET /v1/sessions works with the admin session" "200" "$(http_code -b "$jar" "$APP_URL/v1/sessions")"
assert_eq "GET /auth/me works with the admin session" "200" "$(http_code -b "$jar" "$APP_URL/auth/me")"

summary
