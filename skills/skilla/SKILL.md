---
name: skilla
description: Install, update, list, verify, and remove agent skills (agentskills.io) and Agent Plugins (agent-plugins.org) using the skilla CLI. Use whenever the user asks to install, add, update, or remove an agent skill or plugin from a git repository or catalog — in any AI coding CLI (Claude Code, Devin, Cursor, ...) — instead of vendor-specific plugin commands.
license: MIT
compatibility: Requires bash, git and jq; cosign only for the 'verify' command
allowed-tools: Bash(skilla:*) Bash(curl:*) Read
metadata:
  version: "0.4.1"
  author: "@junior"
  category: meta
  tags: "skills, plugins, installer, agentskills, agent-plugins, cli"
---

# skilla — the generic agent-skill and plugin installer

`skilla` is a single-file bash CLI (no Node.js) that installs, from any git repository:

- **Agent Skills** ([agentskills.io](https://agentskills.io/specification)) — a source
  with `skills/<name>/SKILL.md` directories (a catalog) or a single root `SKILL.md`.
- **Agent Plugins** ([agent-plugins.org](https://agent-plugins.org/specification) 1.0.0)
  — a `plugin.json` package bundling `skills/` and an `mcp.json`.

It resolves declared dependencies, tracks versions in a registry, and can verify
cosign-signed catalogs. Use it instead of vendor-specific mechanisms
(`gh skill install`, `devin plugins install`, marketplace UIs) so the same skills
and plugins work across AI CLIs.

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
skilla repo ls <git-url>                 # browse a repo's skills (name · version · description)
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

## Agent Plugins (agent-plugins.org 1.0.0)

A plugin is a directory with a `plugin.json` manifest plus components in fixed
locations: `skills/<name>/SKILL.md` and `mcp.json`.

```bash
skilla plugin ls <git-url>               # inspect a plugin: manifest, skills, MCP servers
skilla plugin add <git-url>              # install package + its skills + its plugin data
skilla plugin ls                         # what's installed
skilla plugin info <name>                # manifest, components, PLUGIN_ROOT / PLUGIN_DATA
skilla plugin mcp <name>                 # mcp.json with ${PLUGIN_ROOT}/${PLUGIN_DATA} expanded
skilla plugin remove <name>              # package + its skills + its data
skilla plugin validate [dir]             # conformance-check (for plugin authors)
skilla plugin init [dir]                 # scaffold a conformant plugin.json
```

- `plugin add` keeps the package tree intact at `.agents/plugins/<name>/` (so
  `${PLUGIN_ROOT}` resolves) and *also* copies its skills into the skills dir where
  agents index them. `.agents/plugin-data/<name>/` is the persistent `PLUGIN_DATA`.
- skilla does **not** run MCP servers. `skilla plugin mcp <name>` prints a ready-to-paste
  config with the placeholders expanded — the user's host launches the server.
- Plain `skilla add` on a plugin source still works: it installs the skills only and
  says so.

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
- "install the plugin at `<repo>`" → `skilla plugin add <repo>`. If unsure whether a
  source is a plugin or a plain catalog, run `skilla plugin ls <repo>` first — it says
  so when there is no `plugin.json`.
- "what skills do I have?" → `skilla list` (and `skilla list --scope user`);
  for plugins, `skilla plugin ls`.
- "update my skills" → `skilla update`.
- "is my plugin valid?" / authoring a plugin → `skilla plugin validate .`
- Dependencies (`metadata.requires` or `requires:` in SKILL.md frontmatter, or plugin.json
  `requiredSkills`) are resolved automatically from the same source — do not install them
  by hand.
- If the catalog publishes signed release bundles, verify before trusting:
  `skilla verify skills-<ver>.tgz --key trust/cosign.pub`.
- After installing into a project, remind the user to commit `.agents/skills/` if
  they want the skill shared with the team via the repo.

## Notes

- Sources can be HTTPS or SSH git URLs (internal GitLab or GitHub both work).
- skilla never runs skill code, install hooks or MCP servers — it copies files and
  records name/version/source in a registry (`.agents/registry.json` for skills,
  `.agents/plugins.json` for plugins, per scope).
- A skill's version comes from `metadata.version` in its SKILL.md frontmatter — the
  agentskills.io spec has no top-level `version:` field. A top-level `version:` is
  still read as a legacy fallback.
- Repository & docs: https://github.com/junior/skilla
