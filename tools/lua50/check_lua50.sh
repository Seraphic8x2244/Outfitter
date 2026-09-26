#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_ROOT=""

if [[ -n "${LUA50_LUAC:-}" ]]; then
  LUAC="$LUA50_LUAC"
  if [[ ! -x "$LUAC" ]]; then
    echo "LUA50_LUAC is not executable: $LUAC" >&2
    exit 2
  fi
else
  TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/vanilla-lua50-check.XXXXXX")"
  trap 'rm -rf "$TEMP_ROOT"' EXIT
  LUAC="$TEMP_ROOT/luac"
  "$SCRIPT_DIR/build_lua50.sh" "$LUAC" >/dev/null
fi

if [[ $# -eq 0 ]]; then
  set -- .
fi

files=()
for input in "$@"; do
  if [[ -f "$input" ]]; then
    files+=("$input")
  elif [[ -d "$input" ]]; then
    while IFS= read -r -d '' file; do
      case "$file" in
        */tools/lua50/vendor/*) continue ;;
      esac
      files+=("$file")
    done < <(find "$input" -type f -name '*.lua' -print0)
  else
    echo "Not a file or directory: $input" >&2
    exit 2
  fi
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No Lua files found to check." >&2
  exit 2
fi

for file in "${files[@]}"; do
  "$LUAC" -p -- "$file"
done

echo "Lua 5.0.3 syntax check passed: ${#files[@]} file(s)."
