#!/usr/bin/env bash
# shellcheck disable=SC2015  # `cond && pass || fail` is intentional; pass/fail are echo/exit (C never runs spuriously)
# Self-contained tests for skill-manager. Builds a fixture "catalog" git repo
# (skill-b depends on skill-a), then asserts install behaviour. Needs git + jq.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SM="$HERE/../skill-manager"
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
"$SM" --version | grep -q '^skill-manager ' && pass "--version prints version" || fail "--version"

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

echo
echo "ALL TESTS PASSED"
