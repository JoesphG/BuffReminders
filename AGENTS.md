# Repository Guidelines

## Project Structure & Module Organization
- Root Lua modules: `Core.lua`, `Buffs.lua`, `State.lua`, `Components.lua`, `BuffReminders.lua`, `Options.lua`, `types.lua`.
- Addon manifest: `BuffRemindersV2.toc` lists load order and metadata.
- Third‑party libs: `Libs/` (LibStub, CallbackHandler, LibSharedMedia).
- Assets: `images/` and `icon.tga`.
- Project docs: `README.md`, `CURSEFORGE.md`.

## Build, Test, and Development Commands
This repo uses a Makefile for static checks and formatting:
- `make lint` runs `luacheck .` for Lua linting (config in `.luacheckrc`).
- `make format` runs `stylua .` (format rules in `stylua.toml`).
- `make typecheck` runs `lua-language-server --check . --checklevel=Warning`.
- `make check` runs typecheck + lint + `stylua --check .`.

## Coding Style & Naming Conventions
- Indentation: 4 spaces; line width 120; Unix line endings (see `stylua.toml`).
- Quotes: `stylua` prefers double quotes when possible.
- Globals: WoW API globals are allowed via `.luacheckrc`. Avoid introducing new globals unless they are registered there.
- Files are PascalCase (`BuffReminders.lua`) and grouped by responsibility (Core/State/UI/Options).

## Testing Guidelines
- No test framework or test directory is present.
- Use `make check` for static verification before changes.
- Validate behavior in‑game (e.g., `/br` options panel, buff tracking, glow warnings).

## Commit & Pull Request Guidelines
- Git history is not available in this checkout, so no established commit message convention can be inferred.
- Suggested practice: short, imperative summaries (e.g., “Fix aura tracking in M+”) and reference issues when relevant.
- PRs should describe user‑visible changes and include screenshots/GIFs for UI changes (see `images/` patterns).

## Configuration Tips
- Addon load order and dependencies live in `BuffRemindersV2.toc`.
- Lint exclusions for bundled libraries are handled by `.luacheckrc` (`exclude_files = { "Libs/" }`).
