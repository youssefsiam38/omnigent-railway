#!/usr/bin/env bash
# shellcheck disable=SC2015
# Live test of a deployed template: the flows the local smoke covers, over HTTPS.
#
#   OMNIGENT_ADMIN_PASSWORD_FILE=./admin-password tests/railway-smoke.sh https://<app-domain>
#
# Optional: OMNIGENT_ADMIN_USERNAME (default admin). Read-only apart from logins. Secrets come from a file.
set -euo pipefail
REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd); export REPO_ROOT
[ $# -ge 1 ] || { sed -n '3,6p' "$0"; exit 2; }
APP_URL=${1%/}; export APP_URL
# shellcheck source=tests/lib.sh
. "$REPO_ROOT/tests/lib.sh"
trap 'rm -rf "$TEST_TMP"' EXIT

: "${OMNIGENT_ADMIN_PASSWORD_FILE:?set OMNIGENT_ADMIN_PASSWORD_FILE}"
ADMIN_USER=${OMNIGENT_ADMIN_USERNAME:-admin}
ADMIN_PW=$(tr -d '\n' < "$OMNIGENT_ADMIN_PASSWORD_FILE")

section "availability over HTTPS"
wait_for_code "$APP_URL/health" 200 300 && pass "/health returns 200 over HTTPS" || die "not healthy"

section "the setup race is closed and login works over HTTPS"
assert_eq "POST /auth/setup is refused (admin already seeded)" "409" \
  "$(http_code -X POST "$APP_URL/auth/setup" -H 'Content-Type: application/json' --data '{"username":"x","password":"x-pw-123456"}')"
bad=$(http_code -X POST "$APP_URL/auth/login" -H 'Content-Type: application/json' --data '{"username":"admin","password":"definitely-wrong"}')
assert_eq "a wrong password is rejected" "401" "$bad"
jar="$TEST_TMP/jar"
login_cookiejar "$ADMIN_USER" "$ADMIN_PW" "$jar" && pass "the seeded admin logs in over HTTPS" || fail "admin login failed"

section "an authenticated API call works over HTTPS"
assert_eq "GET /v1/sessions requires authentication" "401" "$(http_code "$APP_URL/v1/sessions")"
assert_eq "GET /v1/sessions works with the admin session" "200" "$(http_code -b "$jar" "$APP_URL/v1/sessions")"

summary
