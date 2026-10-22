Dwarven Accent 1.0
=====================

A starter WoW: Forever addon that rewrites selected phrases in your outgoing
chat into a light Scots-inspired dwarf voice.

INSTALL
1. Close WoW.
2. Extract the DwarvenAccent folder into:
   World of Warcraft\_classic_beta_\Interface\AddOns\ (or whatever the folder for the release version of Forever is called)
   (Your Forever installation may use a slightly different client folder.)
3. Launch the game. At character select, enable the addon if needed.
4. Log in and type /dt to see the commands.

COMMANDS
/dt                  Show status/help
/dt on               Enable rewriting
/dt off              Disable rewriting
/dt test <text>      Preview a rewrite locally; it does not send the text

CUSTOMIZING
Open DwarvenAccent.lua in a text editor and edit REPLACEMENTS near the top.
Each entry is { "what you type", "what it becomes" }.
Use lowercase source phrases. Longer phrases are automatically applied first.

The addon deliberately leaves slash commands alone. It does not modify incoming
chat or other players' messages.
