#!/usr/bin/env bash
# shellcheck disable=SC2015  # `cond && pass || fail` is intentional; pass/fail are echo/exit (C never runs spuriously)
# Self-contained tests for skilla. Builds a fixture "catalog" git repo
# (skill-b depends on skill-a), then asserts install behaviour. Needs git + jq.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SM="$HERE/../skilla"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "  ok   - $1"; }
fail() { echo "  FAIL - $1" >&2; exit 1; }

# --- fixture catalog: skill-b requires skill-a -----------------------------
CAT="$TMP/catalog"
mkdir -p "$CAT/skills/skill-a" "$CAT/skills/skill-b"
cat > "$CAT/skills/skill-a/SKILL.md" <<'EOF'
---
name: skill-a
version: 1.2.3
description: Fixture skill A.
---
# skill-a
EOF
cat > "$CAT/skills/skill-b/SKILL.md" <<'EOF'
---
name: skill-b
version: 0.9.0
requires:
  - skill-a
description: Fixture skill B (depends on A).
---
# skill-b
EOF
git -C "$CAT" init -q
git -C "$CAT" add -A
git -C "$CAT" -c user.email=t@example.com -c user.name=tester commit -qm init

DEST="$TMP/proj/.agents/skills"
REG="$TMP/proj/.agents/registry.json"

echo "test: version"
"$SM" --version | grep -q '^skilla ' && pass "--version prints version" || fail "--version"

echo "test: parser keeps the source (value flags must not consume it)"
out="$("$SM" add --skill skill-b --check --path "$DEST" "$CAT" 2>&1)"
echo "$out" | grep -qF "Adding skill(s) from: $CAT" \
  && pass "source parsed as the repo, not the --skill value" \
  || { echo "$out"; fail "source mis-parsed"; }

echo "test: --check did not install anything"
[ ! -e "$DEST" ] || [ -z "$(ls -A "$DEST" 2>/dev/null)" ] \
  && pass "--check installed nothing" || fail "--check should not install"

echo "test: dependency resolution (installing skill-b pulls skill-a)"
"$SM" add --skill skill-b --path "$DEST" "$CAT" >/dev/null 2>&1
[ -f "$DEST/skill-b/SKILL.md" ] && pass "skill-b installed" || fail "skill-b missing"
[ -f "$DEST/skill-a/SKILL.md" ] && pass "skill-a pulled as a dependency" || fail "dependency skill-a missing"

echo "test: registry records both, with versions from frontmatter"
[ "$(jq -r '.["skill-a"].version' "$REG")" = "1.2.3" ] && pass "skill-a -> 1.2.3" || fail "skill-a version"
[ "$(jq -r '.["skill-b"].version' "$REG")" = "0.9.0" ] && pass "skill-b -> 0.9.0" || fail "skill-b version"

echo "test: remove is registry-scoped"
"$SM" remove skill-b -y --path "$DEST" >/dev/null 2>&1
[ ! -e "$DEST/skill-b" ] && pass "skill-b removed" || fail "skill-b not removed"
[ -f "$DEST/skill-a/SKILL.md" ] && pass "skill-a left intact" || fail "skill-a should remain"

echo "test: help uses the bare name, path only on the Location line"
help_out="$("$SM" -h)"
echo "$help_out" | grep -q '^Usage: skilla ' && pass "usage shows bare 'skilla'" || fail "usage shows a path"
sm_dir="$(cd "$(dirname "$SM")" && pwd -P)"
[ "$(echo "$help_out" | grep -c "$sm_dir")" -eq 1 ] \
  && pass "script path appears exactly once (Location line)" || fail "path leaks beyond Location"
echo "$help_out" | grep -q '^Location: ' && pass "Location line present" || fail "Location line missing"

echo "test: --scope validation"
"$SM" --scope banana list >/dev/null 2>&1 && fail "--scope banana accepted" || pass "invalid scope rejected"

echo "test: --scope user == -g (installs under \$HOME/.agents/skills)"
FAKEHOME="$TMP/home"; mkdir -p "$FAKEHOME"
HOME="$FAKEHOME" "$SM" add --scope user --skill skill-a "$CAT" >/dev/null 2>&1
[ -f "$FAKEHOME/.agents/skills/skill-a/SKILL.md" ] \
  && pass "--scope user installed to ~/.agents/skills" || fail "--scope user wrong destination"
scope_out="$(HOME="$FAKEHOME" "$SM" list --scope user 2>/dev/null)"   # capture first: grep -q + pipefail = SIGPIPE race
echo "$scope_out" | grep -q 'Installed skills (user)' \
  && pass "list labels the scope 'user'" || fail "scope label"

echo "test: repo ls lists skills with descriptions (no install)"
ls_out="$("$SM" repo ls "$CAT" 2>/dev/null)"
echo "$ls_out" | grep -q 'skill-a' && echo "$ls_out" | grep -q 'Fixture skill A.' \
  && pass "repo ls shows name + description" || { echo "$ls_out"; fail "repo ls output"; }
echo "$ls_out" | grep -q 'skill-b' && pass "repo ls lists every skill" || fail "repo ls missing skill-b"
echo "$ls_out" | grep -q '1.2.3' && pass "repo ls shows versions" || fail "repo ls missing version"

# --- Agent Plugins 1.0.0 ---------------------------------------------------
PSCHEMA="https://agent-plugins.org/schemas/1.0.0/plugin.schema.json"
MSCHEMA="https://agent-plugins.org/schemas/1.0.0/mcp.schema.json"

PG="$TMP/pg"
mkdir -p "$PG/skills/deploy"
cat > "$PG/plugin.json" <<EOF
{
  "\$schema": "$PSCHEMA",
  "name": "acme-tools",
  "version": "2.1.0",
  "description": "Fixture plugin.",
  "author": { "name": "Acme" },
  "license": "MIT",
  "extensions": { "com.example.client": { "menu": true } }
}
EOF
cat > "$PG/mcp.json" <<EOF
{
  "\$schema": "$MSCHEMA",
  "mcpServers": {
    "database": {
      "type": "stdio",
      "command": "npx",
      "args": ["--config", "\${PLUGIN_ROOT}/config/db.json"],
      "cwd": "\${PLUGIN_ROOT}",
      "env": { "DATA_DIR": "\${PLUGIN_DATA}/database" }
    }
  }
}
EOF
# version lives under `metadata:` — the agentskills.io location, not a top-level key.
cat > "$PG/skills/deploy/SKILL.md" <<'EOF'
---
name: deploy
description: Deploy the service. Use when the user asks to ship or roll back.
metadata:
  version: "2.1.0"
---
# deploy
EOF
git -C "$PG" init -q
git -C "$PG" add -A
git -C "$PG" -c user.email=t@example.com -c user.name=tester commit -qm init

echo "test: metadata.version is read (agentskills.io has no top-level version:)"
PDEST="$TMP/mproj/.agents/skills"
"$SM" add --skill deploy --path "$PDEST" "$PG" >/dev/null 2>&1
[ "$(jq -r '.deploy.version' "$TMP/mproj/.agents/registry.json")" = "2.1.0" ] \
  && pass "version resolved from metadata.version" || fail "metadata.version not read"

echo "test: plugin validate accepts a conformant plugin"
"$SM" plugin validate "$PG" >/dev/null 2>&1 && pass "conformant plugin validates" || fail "valid plugin rejected"

echo "test: plugin validate rejects a fatally invalid manifest"
BAD="$TMP/bad"; mkdir -p "$BAD"
cat > "$BAD/plugin.json" <<EOF
{ "\$schema": "$PSCHEMA", "name": "Bad--Name", "keywords": "nope",
  "author": { "twitter": "@a" }, "requiredSkills": ["x"] }
EOF
bad_out="$("$SM" plugin validate "$BAD" 2>&1)" && fail "invalid manifest accepted" || pass "invalid manifest rejected"
echo "$bad_out" | grep -q "must not contain '--'" && pass "flags '--' in name" || fail "missed '--' in name"
echo "$bad_out" | grep -q "'keywords' must be an array" && pass "flags non-array keywords" || fail "missed keywords type"
echo "$bad_out" | grep -q "outside {name,email,url}" && pass "flags closed author object" || fail "missed author field"
echo "$bad_out" | grep -q "unknown top-level field(s) ignored: requiredSkills" \
  && pass "unknown field reported as non-fatal" || fail "unknown field not reported"

echo "test: plugin validate enforces the mcp.json rules"
MBAD="$TMP/mbad"; mkdir -p "$MBAD"
cat > "$MBAD/plugin.json" <<EOF
{ "\$schema": "$PSCHEMA", "name": "mbad" }
EOF
cat > "$MBAD/mcp.json" <<EOF
{ "\$schema": "$MSCHEMA", "mcpServers": {
  "a": { "type": "stdio", "command": "node server.js", "cwd": "../out",
         "env": { "PLUGIN_ROOT": "/x" } },
  "b": { "type": "streamable-http", "url": "http://evil.example/mcp" },
  "c": { "type": "websocket", "url": "wss://x" } } }
EOF
mbad_out="$("$SM" plugin validate "$MBAD" 2>&1)" || true
echo "$mbad_out" | grep -q "one executable token" && pass "stdio command must be one token" || fail "missed multi-token command"
echo "$mbad_out" | grep -q "must not set reserved PLUGIN_ROOT" && pass "reserved env key rejected" || fail "missed reserved env key"
echo "$mbad_out" | grep -q "escapes its containment boundary" && pass "cwd containment enforced" || fail "missed cwd escape"
echo "$mbad_out" | grep -q "plain http is only allowed for loopback" && pass "non-loopback http rejected" || fail "missed http/https rule"
echo "$mbad_out" | grep -q "unsupported transport 'websocket'" && pass "unknown transport skipped" || fail "missed unknown transport"

echo "test: plugin add installs package + skills + plugin data"
PROJ="$TMP/plug"; mkdir -p "$PROJ"
( cd "$PROJ" && "$SM" plugin add "$PG" ) >/dev/null 2>&1
[ -f "$PROJ/.agents/plugins/acme-tools/plugin.json" ] && pass "package tree kept intact" || fail "plugin package not installed"
[ -f "$PROJ/.agents/skills/deploy/SKILL.md" ] && pass "skills surfaced in the skills dir" || fail "plugin skill not installed"
[ -d "$PROJ/.agents/plugin-data/acme-tools" ] && pass "PLUGIN_DATA created" || fail "PLUGIN_DATA missing"
[ "$(jq -r '.["acme-tools"].version' "$PROJ/.agents/plugins.json")" = "2.1.0" ] \
  && pass "plugin registry records the version" || fail "plugin registry version"
[ "$(jq -r '.deploy.plugin' "$PROJ/.agents/registry.json")" = "acme-tools" ] \
  && pass "skill is attributed to its plugin" || fail "skill plugin attribution"

echo "test: plugin mcp expands the placeholders to absolute paths"
mcp_out="$( cd "$PROJ" && "$SM" plugin mcp acme-tools )"
root="$(cd "$PROJ/.agents/plugins/acme-tools" && pwd -P)"
[ "$(echo "$mcp_out" | jq -r '.mcpServers.database.cwd')" = "$root" ] \
  && pass "\${PLUGIN_ROOT} expanded to an absolute path" || fail "PLUGIN_ROOT expansion"
echo "$mcp_out" | jq -e '.mcpServers.database.args[1] | test("/config/db.json$")' >/dev/null \
  && pass "args expanded" || fail "args not expanded"
echo "$mcp_out" | jq -e '.mcpServers.database.env.PLUGIN_DATA | startswith("/")' >/dev/null \
  && pass "PLUGIN_DATA provided to the subprocess env" || fail "PLUGIN_DATA not injected"
echo "$mcp_out" | jq -e '.mcpServers.database.command == "npx"' >/dev/null \
  && pass "command left unexpanded (per spec)" || fail "command must not be expanded"

echo "test: plugin remove takes the package, its skills and its data"
( cd "$PROJ" && "$SM" plugin remove acme-tools -y ) >/dev/null 2>&1
[ ! -e "$PROJ/.agents/plugins/acme-tools" ] && pass "package removed" || fail "package left behind"
[ ! -e "$PROJ/.agents/skills/deploy" ] && pass "plugin's skill removed" || fail "skill left behind"
[ ! -e "$PROJ/.agents/plugin-data/acme-tools" ] && pass "plugin data removed" || fail "plugin data left behind"

echo "test: plugin init scaffolds something that validates"
NEW="$TMP/newpg"; mkdir -p "$NEW"
"$SM" plugin init "$NEW" >/dev/null 2>&1
"$SM" plugin validate "$NEW" >/dev/null 2>&1 && pass "scaffold is conformant" || fail "scaffold does not validate"

echo "test: add on a plugin source installs skills and says so"
ap_out="$( cd "$TMP" && "$SM" add --path "$TMP/aproj/.agents/skills" "$PG" 2>&1 )"
echo "$ap_out" | grep -q "Source is an Agent Plugin: acme-tools" \
  && pass "plugin source detected by 'add'" || fail "plugin source not detected"
[ -f "$TMP/aproj/.agents/skills/deploy/SKILL.md" ] && pass "skills still install" || fail "skills not installed"

echo
echo "ALL TESTS PASSED"
