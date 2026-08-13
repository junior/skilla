# Changelog

All notable changes are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/); versioning is SemVer.

## [Unreleased]
### Fixed
- `plugin init` could scaffold a `plugin.json` that fails its own validator: the
  directory name was mapped character-by-character, so `my__tools` became the
  manifest-illegal `my--tools`. Repeated `-`/`.` runs are now squeezed, leading and
  trailing non-alphanumerics stripped, and the result truncated to 64 characters.

## [0.4.0] - 2026-08-13
### Added
- **Agent Plugins 1.0.0 support** ([agent-plugins.org](https://agent-plugins.org/specification)),
  the vendor-neutral packaging standard published 2026-08-06 by a TSC of Amazon, Cursor,
  Google, Microsoft, OpenAI and Vercel. New `skilla plugin` command group:
  - `plugin ls [source]` — inspect a plugin at a git URL (manifest, skills, MCP servers,
    extension namespaces) without installing, or list installed plugins.
  - `plugin add <source>` — install the package tree intact at `.agents/plugins/<name>/`
    (so `${PLUGIN_ROOT}` resolves), copy its skills into the skills dir where agents index
    them, and create the persistent `.agents/plugin-data/<name>/` (`PLUGIN_DATA`).
  - `plugin info <name>`, `plugin remove <name>` (package + its skills + its data).
  - `plugin mcp <name>` — print the plugin's `mcp.json` with `${PLUGIN_ROOT}`/`${PLUGIN_DATA}`
    expanded to absolute paths and both variables injected into each stdio server's `env`,
    ready to paste into whatever host launches MCP servers. skilla still runs nothing.
  - `plugin validate [dir]` — conformance-check the closed manifest schema, the `name`
    grammar, the closed `author` object, extension namespacing, `mcp.json` transports
    (single-token `command`, `cwd` containment, reserved env keys, http-only-for-loopback
    URLs, case-insensitive duplicate headers) and each skill's frontmatter.
  - `plugin init [dir]` — scaffold a conformant `plugin.json` + `skills/`.
- Plugins are tracked in their own `plugins.json` registry, so plugin and skill names can
  never collide; skills installed from a plugin record their originating `plugin`.
- `add` now recognises an Agent Plugins source, validates its manifest before copying, and
  says that it is installing the skills only.
- `metadata.requires` (a spec-safe string list) and `plugin.json`
  `extensions["dev.skilla"].requiredSkills` as dependency sources.
### Changed
- Spec failure boundaries are honoured: unknown top-level manifest fields and a non-object
  `extensions` are reported but non-fatal; any other manifest violation rejects the plugin;
  an invalid `mcp.json` disables MCP only; a bad server entry or skill is skipped.
### Fixed
- **Skill versions are read from `metadata.version`.** The
  [agentskills.io spec](https://agentskills.io/specification) defines no top-level
  `version:` field — `metadata` is where it belongs — so versions were silently falling
  through to the commit hash for conformant skills. A top-level `version:` is still read
  as a legacy fallback.
- The shipped `skills/skilla/SKILL.md` is now spec-conformant: no top-level `version:`,
  no non-spec `triggers:`, `allowed-tools` as the specified space-separated string, and
  `metadata` values flattened to strings.

## [0.3.0] - 2026-07-10
### Added
- `skilla repo ls <source>` — list a repository's skills (name · version · description)
  without installing anything.
- Partial + sparse clones: `add --skill`, `update`, and `repo ls` download only the
  needed skill's files (dependencies materialize on demand; automatic fallback to a
  plain shallow clone), so big catalogs like microsoft/azure-skills or nvidia/skills
  don't cost a full checkout.
- README badges (CI · release · homebrew · agentskills.io · AI-agents · pure-bash · MIT).

## [0.2.1] - 2026-07-10
### Fixed
- `verify` uses `--insecure-ignore-tlog=true`: internal-PKI bundles carry no public
  transparency-log entry (signed with an empty-services signing config), and offline
  verification must not require the public Sigstore TUF/Rekor infrastructure.

## [0.2.0] - 2026-07-08
### Added
- `--scope <user|project>` — the explicit way to pick where skills live
  (`project` = `./.agents/skills/`, the default; `user` = `~/.agents/skills/`).
  `-g/--global` is now shorthand for `--scope user`.
- **The `skilla` skill** (`skills/skilla/SKILL.md`) — an agentskills.io skill that
  teaches AI CLIs (Claude Code, Devin, ...) to install/manage skills via skilla;
  self-hosted: `skilla add <this-repo> --skill skilla`.
- Homebrew tap: `brew install junior/tap/skilla`.
### Changed
- Help output uses the plain `skilla` name instead of the invocation path
  (`$0`) everywhere, with a single `Location:` line showing where the script lives.
- `list` labels the scope `user` (or `custom path`) instead of `global`.
### Fixed
- `verify` uses the cosign v3 bundle API (`--bundle`, default `<artifact>.bundle`).

## [0.1.0] - 2026-06-29
### Added
- Install agentskills.io skills from git repos: `add`, `update`, `list`, `info`, `remove`.
- Project / global / custom (`--path`) scopes with a JSON registry.
- Dependency resolution: a skill's `requires:` (frontmatter) / `requiredSkills`
  (`plugin.json`) are installed from the same source (transitive closure).
- Version resolved from `SKILL.md` frontmatter (`plugin.json` fallback, then commit hash).
- `--check` dry-run, `--force` reinstall, `-s/--skill` single-skill, `version` / `--version`.
- Single-pass argument parser (value flags no longer swallow following flags),
  portable UTC timestamps, and `set -e`-safe control flow.
