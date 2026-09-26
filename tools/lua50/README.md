# Lua 5.0.3 syntax checker

This directory provides a reproducible Lua 5.0.3 compiler check for Vanilla WoW 1.12.1 addon development.

## What is included

- `vendor/lua-5.0.3/` — the Lua 5.0.3 compiler source needed by this checker.
- `build_lua50.sh` — compiles a temporary Lua 5.0.3 `luac` with the host C compiler.
- `check_lua50.sh` — runs `luac -p` against Lua files or directories.
- `selftest.sh` — proves the checker accepts Lua 5.0.3 syntax, rejects later `#` length syntax, and enforces the Lua 5.0.3 200-local compiler limit.

The vendored files are the compiler subset from the Lua 5.0.3 distribution. The included original `MANIFEST` identifies the distribution as 19 June 2006. Lua's official download archive is `lua-5.0.3.tar.gz`; lua.org publishes this SHA-256:

`1193a61b0e08acaa6eee0eecf29709179ee49c71baebc59b682a25c3b5a45671`

Lua 5.0.3 is distributed under the MIT license. The original `COPYRIGHT` file is included with the vendored source.

## Requirements

- Bash
- an ANSI C compiler (`cc` by default, or set `CC`)

No installed Lua interpreter or Lua compiler is required.

## Usage

Check an addon checkout:

```sh
bash /path/to/VanillaTemplate/tools/lua50/check_lua50.sh /path/to/Addon
```

Check explicit files:

```sh
bash /path/to/VanillaTemplate/tools/lua50/check_lua50.sh Addon.lua Debug.lua
```

Run the tool's verification:

```sh
bash tools/lua50/selftest.sh
```

A successful run is a real Lua 5.0.3 compiler/syntax check. It is not an in-game WoW 1.12.1 runtime test.
