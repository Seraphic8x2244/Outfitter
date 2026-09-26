#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="$SCRIPT_DIR/vendor/lua-5.0.3"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 OUTPUT_PATH" >&2
  exit 2
fi

CC_BIN="${CC:-cc}"
if ! command -v "$CC_BIN" >/dev/null 2>&1; then
  echo "Lua 5.0.3 build requires an ANSI C compiler (tried '$CC_BIN')." >&2
  exit 2
fi

read -r -a CFLAGS_ARRAY <<< "${LUA50_CFLAGS:--O2 -fcommon}"

OUTPUT="$1"
mkdir -p "$(dirname "$OUTPUT")"

"$CC_BIN" "${CFLAGS_ARRAY[@]}" \
  -DLUA_OPNAMES \
  -I"$VENDOR_DIR/include" \
  -I"$VENDOR_DIR/src" \
  "$VENDOR_DIR/src/lapi.c" \
  "$VENDOR_DIR/src/lcode.c" \
  "$VENDOR_DIR/src/ldebug.c" \
  "$VENDOR_DIR/src/ldo.c" \
  "$VENDOR_DIR/src/ldump.c" \
  "$VENDOR_DIR/src/lfunc.c" \
  "$VENDOR_DIR/src/lgc.c" \
  "$VENDOR_DIR/src/llex.c" \
  "$VENDOR_DIR/src/lmem.c" \
  "$VENDOR_DIR/src/lobject.c" \
  "$VENDOR_DIR/src/lopcodes.c" \
  "$VENDOR_DIR/src/lparser.c" \
  "$VENDOR_DIR/src/lstate.c" \
  "$VENDOR_DIR/src/lstring.c" \
  "$VENDOR_DIR/src/ltable.c" \
  "$VENDOR_DIR/src/ltm.c" \
  "$VENDOR_DIR/src/lundump.c" \
  "$VENDOR_DIR/src/lvm.c" \
  "$VENDOR_DIR/src/lzio.c" \
  "$VENDOR_DIR/src/lib/lauxlib.c" \
  "$VENDOR_DIR/src/luac/luac.c" \
  "$VENDOR_DIR/src/luac/print.c" \
  -lm \
  -o "$OUTPUT"

chmod +x "$OUTPUT"
"$OUTPUT" -v
