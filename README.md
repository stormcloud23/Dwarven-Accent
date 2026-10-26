# Dwarven Accent — Advanced 1.1

A configurable, RP-friendly Scots-inspired outgoing chat rewriter for **World of Warcraft: Forever**. Designed to add a little dwarven character to everyday speech without turning every sentence into an exaggerated accent.

## Downloads

- **Advanced 1.1 (this branch):** [ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/advanced.zip)
- **Simple 1.0 (unchanged `main` branch):** [ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/main.zip)

Both editions use the same addon identity. **Install only one at a time.**

## Installation

1. Close WoW: Forever and extract the ZIP of your chosen edition.
2. Rename the extracted folder to **`DwarvenAccent`**.
3. Copy that folder into your client installation's `Interface\AddOns\` directory (for example, `World of Warcraft\_classic_beta_\Interface\AddOns\`).
4. Check that `DwarvenAccent.toc`, `DwarvenAccent.lua`, `Vocabulary.lua`, `Core.lua` and `Options.lua` are **directly inside** the `DwarvenAccent` folder.
5. Start the game and type **`/da config`** to open the settings window. The addon also provides a shortcut in the modern WoW AddOns settings list when supported.

## Commands

| Command | Effect |
| --- | --- |
| `/da` | Show status and commands |
| `/da on` / `/da off` | Turn accent rewriting on or off (saved) |
| `/da config` | Open the in-game settings window |
| `/da subtle`, `/da balanced`, `/da heavy` | Select an accent intensity preset |
| `/da test <message>` | Preview what a message would become without sending it |

## In-game options

- **Accent strength:** Subtle (up to 2 substitutions), Balanced (up to 3, the default), Heavy (up to 7).
- **Custom limit:** Set a fixed substitution cap per message, or use Auto to follow the preset.
- **Categories:** Enable/disable Phrases & greetings, Contractions, Pronouns, Scots vocabulary, Everyday words, Exclamations, and Strong language.
- **Individual words:** Search vocabulary and turn any translation on or off without editing Lua.
- **Preview:** Type into the preview field to see the effect before chatting.
- **Reset:** Restore the default configuration.

Settings are kept in the account-wide `DwarvenAccentDB` SavedVariables table. Preset limits are intentionally conservative, and the default Balanced preset excludes the most aggressive substitutions. The original word list is retained, with duplicate entries removed and some substitutions moved to Heavy.

## RP protections

- Each eligible phrase is processed **once**. Replacements cannot cascade into further replacements.
- Whole-word matching and capitalization handling (including standalone `I`).
- Leave `((out-of-character text))` unchanged, including an unfinished OOC block.
- Preserve `[bracketed sections]`, full WoW item/spell hyperlinks, and common URLs.
- Leave messages beginning with `/` untouched. The addon does **not** modify incoming chat, and does not automatically insert random catchphrases.
- Context safeguard: `pretty sure`/`pretty good` and similar degree expressions do not become `bonnie sure`/`bonnie good`.

## Developer notes

`Vocabulary.lua` holds rules and categories, `Core.lua` handles deterministic transformation and settings, `Options.lua` provides the UI, and `DwarvenAccent.lua` handles WoW event integration. Run `lua5.1 tests/run.lua` from the repo root to execute the included test suite. A GitHub Actions workflow also runs tests on pushes to the `advanced` branch.

**Compatibility:** Kept the original Forever `## Interface: 16001` and `ChatFrame.OnEditBoxPreSendText` callback. Client variants may differ; if the callback is not available, the addon reports that chat rewriting did not register. The in-game settings window has not yet been validated inside a live Forever client.
