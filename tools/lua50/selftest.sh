#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/vanilla-lua50-selftest.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT

LUAC="$TMP_ROOT/luac"
"$SCRIPT_DIR/build_lua50.sh" "$LUAC" >/dev/null

cat > "$TMP_ROOT/valid.lua" <<'LUA'
local values = { 1, 2, 3 }
local total = 0

for i = 1, table.getn(values) do
  total = total + values[i]
end

local function double(value)
  return value * 2
end

return double(total)
LUA

cat > "$TMP_ROOT/modern.lua" <<'LUA'
local values = { 1, 2, 3 }
return #values
LUA

{
  printf 'local '
  for ((i = 1; i <= 201; i++)); do
    if ((i > 1)); then printf ', '; fi
    printf 'v%d' "$i"
  done
  printf '\n'
} > "$TMP_ROOT/too-many-locals.lua"

LUA50_LUAC="$LUAC" "$SCRIPT_DIR/check_lua50.sh" "$TMP_ROOT/valid.lua" >/dev/null

if LUA50_LUAC="$LUAC" "$SCRIPT_DIR/check_lua50.sh" "$TMP_ROOT/modern.lua" >"$TMP_ROOT/modern.out" 2>&1; then
  echo "Self-test failed: Lua 5.1+ length syntax unexpectedly compiled." >&2
  exit 1
fi

if LUA50_LUAC="$LUAC" "$SCRIPT_DIR/check_lua50.sh" "$TMP_ROOT/too-many-locals.lua" >"$TMP_ROOT/locals.out" 2>&1; then
  echo "Self-test failed: 201 locals unexpectedly compiled." >&2
  exit 1
fi

if ! grep -qi 'too many local' "$TMP_ROOT/locals.out"; then
  echo "Self-test failed: 201-local rejection did not report the expected compiler limit." >&2
  cat "$TMP_ROOT/locals.out" >&2
  exit 1
fi

echo "Lua 5.0.3 tool self-test passed."
