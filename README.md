# Dwarven Accent — Simple (1.0)

A lightweight Scots-inspired outgoing chat rewriter for **World of Warcraft: Forever**.

**You are viewing the Simple edition (`main`).** Its original 1.0 Lua and TOC files are preserved. New experimental features are developed separately on the `advanced` branch.

## Versions and downloads

The repository has two branches, each containing its own complete addon:

| Version | Purpose | Download |
| --- | --- | --- |
| **Simple** (`main`) | Original 1.0 implementation; kept stable | [Download Simple ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/main.zip) |
| **Advanced** (`advanced`) | Independent copy for experiments and future improvements | [Download Advanced ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/advanced.zip) |

The Advanced branch began as an **exact copy of the Simple addon code**. Until new features are committed to Advanced, both versions behave the same.

## Install (either version)

1. Close WoW: Forever.
2. Download one of the ZIP files above and extract it.
3. **Rename the extracted directory to `DwarvenAccent`** (it will initially be called `Dwarven-Accent-main` or `Dwarven-Accent-advanced`).
4. Put that `DwarvenAccent` directory inside your client's `Interface\AddOns\` folder. For example, your Forever client may use `World of Warcraft\_classic_beta_\Interface\AddOns\`.
5. Make sure `DwarvenAccent.toc` and `DwarvenAccent.lua` are **directly inside** the `DwarvenAccent` directory, not nested inside another folder.
6. Launch the game, enable the addon if necessary, and type `/da` in chat.

**Switching versions:** Both branches intentionally share the same addon ID, directory, and `/da` commands. Install **only one version at a time**; replace the files in `DwarvenAccent` when switching.

## Commands

- `/da` — Show status and help
- `/da on` — Enable rewriting
- `/da off` — Disable rewriting
- `/da test <text>` — Preview a rewrite without sending it

## Customization

Edit the `REPLACEMENTS` list near the top of `DwarvenAccent.lua`:

```lua
{ "thank you", "thank ye" },
```

Source phrases should be lowercase; longer phrases are applied first. The current implementation skips outgoing slash commands and protects balanced `[bracketed content]` from modification (important for linked item names). It does not change incoming chat.

## Development policy

- **`main` / Simple:** Preserve the original lightweight behavior. Make only fixes that are explicitly intended for the simple edition.
- **`advanced`:** Commit new accent features and refactoring here, without merging those changes into `main` unless explicitly requested.
