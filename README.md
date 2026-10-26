# Dwarven Accent — Advanced 1.3 (pre-release)

A configurable, lightweight, RP-friendly Scots-inspired outgoing chat addon for **World of Warcraft: Forever**. Accent comes from predictable vocabulary choices, **not** random catchphrases or intrusive message rewriting.

## Pick your edition

- **[Advanced 1.3 ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/advanced.zip)** — this branch, features below.
- **[Simple 1.0 ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/main.zip)** — the original working beta-tested version. It remains untouched.

Both editions share one addon name, one `/da` command, and one installation directory. **Only install one edition at a time.**

## Installation

1. Close Warcraft Forever and download the ZIP for the edition you want.
2. Extract the ZIP. Rename the extracted directory (`Dwarven-Accent-advanced` or `Dwarven-Accent-main`) to **`DwarvenAccent`**.
3. Copy that directory to your WoW installation's `Interface\\AddOns\\` folder, e.g. `World of Warcraft\\_classic_beta_\\Interface\\AddOns\\` in the old beta client. The release client may use a different directory.
4. Ensure `DwarvenAccent.toc` is **directly** inside that directory, alongside the `.lua` files (not inside another nested directory).
5. Launch the game. Enable the addon if needed, then type `/da config` to see the options window.

You can safely switch editions by replacing the files in the `DwarvenAccent` directory while WoW is closed. Advanced settings may remain in `DwarvenAccentDB`; the Simple version does not use them.

## Commands

| Command | Purpose |
| --- | --- |
| `/da` | Display status and help |
| `/da on` / `/da off` | Enable/disable substitutions (saved) |
| `/da config` | Open the settings window |
| `/da subtle` | Subtle preset: max 2 substitutions/message, tier 1 |
| `/da balanced` | Balanced default: max 3 substitutions/message, tiers 1–2 |
| `/da heavy` | Heavy: max 7 substitutions/message, tiers 1–3 |
| `/da test <message>` | Preview without sending |

## Settings window

- Preset buttons and optional **manual substitution limit** (1–20 or Auto).
- Enable/disable entire categories: phrases, contractions, pronouns, Scots words, everyday words, exclamations, strong language.
- **Per-rule toggles** and a search box; rules now display their tier `[1]`, `[2]`, or `[3]`.
- A **paged list with 11 reusable rows**, avoiding 100+ checkboxes created at once.
- Muted row text indicates a rule excluded by the current preset or category; the checkbox still controls whether that individual rule is enabled.
- Live preview shows the number of actual substitutions.
- Reset all settings to defaults.

Settings are stored account-wide in the game's `DwarvenAccentDB` SavedVariables. There are no external addon dependencies.

## Translation behavior

- Matches whole words case-insensitively and applies longer phrases before shorter competing rules.
- Makes each substitution **once**, without cascading edits of output words.
- Applies a deterministic preset and message substitution cap — no random variability across identical inputs.
- Preserves `((OOC text))` (including unfinished OOC blocks), `[bracketed text]`, full item/spell links, texture/atlas markup, `http(s)`/`www` URLs, and outgoing slash commands.
- Preserves single-letter `I` capitalization: `I` becomes `Ah`, not `AH`.
- Avoids awkward `pretty fast` / `pretty sure` → `bonnie fast` / `bonnie sure`. `pretty` remains a Heavy-only rule and now recognizes an optional descriptive modifier before a visual noun.
- Reclassifies `friend`, `trouble`, `bother`, and the `very` → `bloody` rule as Heavy only; `oh` translates to `och` at Balanced/Heavy.
- Never changes incoming chat or generates new phrases on its own.

## Offline development and tests

Requires Lua 5.1 for the target compatibility suite (other Lua runtimes may work):

```sh
luac5.1 -p Vocabulary.lua Core.lua Options.lua DwarvenAccent.lua tests/*.lua
lua5.1 tests/run.lua
lua5.1 tests/wow_mock.lua
lua5.1 tests/compat.lua
lua5.1 tests/benchmark.lua
```

- `tests/run.lua`: regression cases for word boundaries, presets, case handling, OOC sections, item links, hyperlinks, URLs, markup, and substitution limits.
- `tests/wow_mock.lua`: emulates key WoW frames, settings registration, the working chat callback, UI filtering and rule toggles.
- `tests/compat.lua`: confirms a missing optional settings API or EventRegistry produces graceful behavior rather than a load failure.
- `tests/benchmark.lua`: informational throughput check, never a CI performance gate (desktop Lua timings are not in-game timings).
- The GitHub Actions workflow runs syntax checks, functional tests, mocks, and the benchmark on pushes to `advanced`.

## Compatibility caveat — release test needed November 4, 2026

**Simple 1.0 worked in the Forever beta.** For Advanced we deliberately retain the **same `## Interface: 16001` identifier** and the tested `EventRegistry:RegisterCallback("ChatFrame.OnEditBoxPreSendText", ...)` hook. We have **not** substituted another unverified chat interception method.

Current retail WoW supports `Settings.RegisterCanvasLayoutCategory` / `Settings.RegisterAddOnCategory`, but a future Forever client build may implement a different subset. The standalone `/da config` window works even when the optional Settings integration is absent. A client missing the chat callback will report that rewriting is unavailable; the addon does **not** intercept chat through a riskier fallback.

These mock tests cannot prove that the release client will accept the `.toc` interface version, its widget templates, or its live chat callback. On launch, test `/da config`, `/da test`, `/say`, a linked item, `((OOC))`, and a logout/login persistence cycle. Keep Simple 1.0 ready as a fallback.

### Maintainers

`Vocabulary.lua` holds categories and tiers, `Core.lua` owns matching and SavedVariables handling, `Options.lua` implements the UI, and `DwarvenAccent.lua` is the integration point. Do not merge the advanced branch into `main` unless explicitly requested.

Useful API references: [WoW Settings panels](https://warcraft.wiki.gg/wiki/Creating_a_settings_menu), [WoW hyperlink structure](https://warcraft.wiki.gg/wiki/Hyperlinks).

## Context-sensitive vocabulary (Advanced 1.3)

The core uses a **small, deterministic set of grammar hints** for ambiguous
words; it does not guess with random percentages or depend on external services.
Most rules remain unconditional. A star (`*`) beside a rule in the vocabulary
browser means its translation depends on nearby words.

- **Pretty/beautiful → bonnie** only for a curated list of visual descriptions,
  optionally after one or two visual modifiers (`pretty little village`), not
  in `pretty sure`, `pretty good`, or `beautiful solution`.
- **No → naw/nae** only in recognizable contexts: `No!` → `Naw!` but
  `no gold` → `nae gold`. Ambiguous uses like `no one` remain unchanged.
- **Worry/bother/trouble → fash** only when it takes a personal object (or as
  part of the existing `don't worry` idiom). Noun `trouble` stays untouched.
- **Crazy → barmy**, **very → bloody**, **man → lad**, **ass → arse**, and **that → tha'** have
  conservative contextual checks to avoid changing their meaning (including preventing `that's` → `tha''s`).
- **Wanna → want tae**, correcting the old grammatically awkward `fancy tae`.

Context checks examine the *original* words, before translation, so they never
accidentally treat freshly translated output as new input. Rejected matches do
not consume a message's substitution allowance. No changes to the original
Forever chat callback, the Simple 1.0 branch, or how SavedVariables are stored.

These are **heuristics, not full grammar parsing**. Unknown or ambiguous
constructions are intentionally left unchanged to preserve RP readability.
The test suite includes positive and negative examples for the context-aware
vocabulary; game-specific integration remains unverified until Forever launches.
