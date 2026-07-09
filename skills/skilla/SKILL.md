---
name: skilla
version: 0.2.0
description: Install, update, list, verify, and remove agent skills (agentskills.io spec) using the skilla CLI. Use whenever the user asks to install, add, update, or remove an agent skill from a git repository or skill catalog — in any AI coding CLI (Claude Code, Devin, Cursor, ...) — instead of vendor-specific plugin commands.
allowed-tools:
  - exec
  - read
triggers:
  - user
  - model
metadata:
  author: "@junior"
  owners:
    - "@junior"
  category: meta
  tags:
    - skills
    - installer
    - agentskills
    - cli
---

# skilla — the generic agent-skill installer

`skilla` is a single-file bash CLI (no Node.js) that installs skills following the
[agentskills.io specification](https://agentskills.io/specification) from any git
repository: a source with `skills/<name>/SKILL.md` directories (a catalog) or a
single root `SKILL.md`. It resolves declared dependencies, tracks versions in a
registry, and can verify cosign-signed catalogs. Use it instead of vendor-specific
mechanisms (`gh skill install`, `devin plugins install`, marketplace UIs) so the
same skills work across AI CLIs.

## Preflight

Check it's available; install if not (single file, needs `git` + `jq`):

```bash
command -v skilla || {
  mkdir -p ~/.local/bin
  curl -fsSL https://raw.githubusercontent.com/junior/skilla/main/skilla -o ~/.local/bin/skilla
  chmod +x ~/.local/bin/skilla
}
skilla version
```

Managed alternatives: `mise use -g 'github:junior/skilla[exe=skilla,matching=skilla]'`
or (macOS) `brew install junior/tap/skilla`.

## Core commands

```bash
skilla add <git-url>                     # install every skill in the source
skilla add <git-url> --skill <name>      # one skill (+ its declared dependencies)
skilla add <git-url> --force             # reinstall / overwrite
skilla list                              # what's installed (current scope)
skilla info <name>                       # version, source, dependencies
skilla update [<name>]                   # update one or all (--check = dry look)
skilla remove <name>                     # uninstall (--all -y for everything)
skilla verify <artifact> --key <pub>     # cosign-verify a signed release bundle
skilla help                              # full usage
```

## Scopes — where skills land

- `--scope project` (**default**): `./.agents/skills/` in the current repo — the
  path Devin indexes for that repository; travels with the project.
- `--scope user` (or `-g`): `~/.agents/skills/` — user-global (e.g. Devin Desktop),
  available in every project.
- `--path <dir>`: any custom directory — use this for host-specific skill dirs
  (e.g. `--path .claude/skills` for a Claude Code project, `--path ~/.claude/skills`
  for Claude Code user-wide).

## How to act on user requests

- "install the `<name>` skill from `<repo>`" →
  `skilla add <repo> --skill <name>` (project scope unless they say global/all projects,
  then `--scope user`).
- "install everything from the catalog" → `skilla add <repo>`.
- "what skills do I have?" → `skilla list` (and `skilla list --scope user`).
- "update my skills" → `skilla update`.
- Dependencies (`requires:` in SKILL.md frontmatter, or plugin.json `requiredSkills`)
  are resolved automatically from the same source — do not install them by hand.
- If the catalog publishes signed release bundles, verify before trusting:
  `skilla verify skills-<ver>.tgz --key trust/cosign.pub`.
- After installing into a project, remind the user to commit `.agents/skills/` if
  they want the skill shared with the team via the repo.

## Notes

- Sources can be HTTPS or SSH git URLs (internal GitLab or GitHub both work).
- skilla never runs skill code at install time — it copies files and records
  name/version/source in a registry (`.agents/registry.json` per scope).
- Repository & docs: https://github.com/junior/skilla
