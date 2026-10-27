# Imperial Accent — Experimental 0.1

A Warhammer Fantasy Empire / Reikland-inspired chat rewriting edition for **World of Warcraft: Forever**, forked from the `advanced` branch of Dwarven Accent.

## Download and installation

[Download Imperial Accent ZIP](https://github.com/stormcloud23/Dwarven-Accent/archive/refs/heads/imperial-accent.zip). Extract and rename the folder to `DwarvenAccent` before placing it in the game's `Interface/AddOns` folder. **Install only one edition at a time.** The addon retains the original `/da` commands and `DwarvenAccentDB` settings key for compatibility.

## Voice and tiers

- **Subtle:** German greetings, thanks, yes/no responses, and polite address.
- **Balanced:** Imperial military commands, ranks, comrades, equipment, and expressive vocabulary.
- **Heavy:** Expanded German vocabulary and short sentences, while retaining readable English grammar around substitutions.

Use `/da config`, `/da subtle`, `/da balanced`, `/da heavy`, or `/da test <message>`.

The engine is inherited from Advanced 1.3: deterministic longest-first matching, case preservation, no cascading replacements, per-rule toggles, optional substitution caps (unlimited by default), and protections for links, markup, slash commands, brackets and OOC text.

## Known limitations

This is an experimental vocabulary fork, **not** a full German translator or historical reconstruction. A few German noun substitutions may sound awkward in English sentences. The original Advanced browser review corpus and generated browser vocabulary are still Scots-oriented and must be adapted before the browser testing workshop accurately represents this branch. The Advanced regression tests also contain Scots-specific expected outputs and must be rewritten before CI can be treated as a validation of this edition. Game-client compatibility has not been verified.

The original `advanced` and `main` branches are unchanged.
