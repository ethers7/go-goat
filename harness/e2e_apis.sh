#!/usr/bin/env bash
# go-goat runtime regression — platform routes only, not exploit success.
# Usage: BASE_URL=http://127.0.0.1:8080 ./e2e_apis.sh
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
BASE_URL="${BASE_URL%/}"
BODY="$(mktemp)"
trap 'rm -f "$BODY"' EXIT INT TERM

say() { printf '%s\n' "$*"; }
fail() { say "ERROR: $*"; exit 1; }

http_code() {
  curl -sS "$@" -o "$BODY" -w '%{http_code}'
}

assert_code() {
  got="$1"
  want="$2"
  what="$3"
  case ",$want," in
    *",$got,"*) say "ok $what -> $got" ;;
    *)
      say "body preview:"
      head -c 400 "$BODY"; echo
      fail "$what expected one of [$want], got $got"
      ;;
  esac
}

wait_ready() {
  say "==> Wait GET $BASE_URL/"
  i=0
  while [ "$i" -lt 60 ]; do
    code="$(curl -sS -o "$BODY" -w '%{http_code}' "$BASE_URL/" || true)"
    if [ "$code" = "200" ]; then
      say "app_ready"
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  fail "GET / not 200 after wait"
}

wait_ready

say "==> Home"
code="$(http_code "$BASE_URL/")"
assert_code "$code" "200" "GET /"
grep -q 'received' "$BODY" || fail "GET / body should mention request received"

say "==> Path param (platform, not an exploit)"
code="$(http_code "$BASE_URL/user/e2e")"
assert_code "$code" "200" "GET /user/e2e"
grep -q 'Hello' "$BODY" || fail "GET /user/:name body should contain Hello"
grep -q 'e2e' "$BODY" || fail "GET /user/e2e body should echo the name"

# Route must still exist after remedia. Do not assert ls output / command
# injection — /list is exec.Command("ls"); that is the vuln to close.
say "==> /list still routes"
code="$(http_code "$BASE_URL/list")"
assert_code "$code" "200" "GET /list"

code="$(http_code "$BASE_URL/no-such-route")"
assert_code "$code" "404" "GET /no-such-route"

say "==> Runtime API regression PASSED"
