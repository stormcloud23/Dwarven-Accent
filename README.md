Dwarven Accent 1.0
=====================

A starter WoW: Forever addon that rewrites selected phrases in your outgoing
chat into a light Scots-inspired dwarf voice.

INSTALL
1. Close WoW.
2. Create a DwarvenAccent folder in:
   World of Warcraft\_classic_beta_\Interface\AddOns\ (or whatever the folder for the release version of Forever is called)
   and place the .toc and .lua files in it.
4. Launch the game. At character select, enable the addon if needed.
5. Log in and type /da to see the commands.

COMMANDS
/da                  Show status/help
/da on               Enable rewriting
/da off              Disable rewriting
/da test <text>      Preview a rewrite locally; it does not send the text

CUSTOMIZING
Open DwarvenAccent.lua in a text editor and edit REPLACEMENTS near the top.
Each entry is { "what you type", "what it becomes" }.
Use lowercase source phrases. Longer phrases are automatically applied first.

The addon deliberately leaves slash commands alone. It does not modify incoming
chat or other players' messages.
