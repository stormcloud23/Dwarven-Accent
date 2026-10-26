-- Informational benchmark, not a speed gate: timings vary by CPU and Lua runtime.
local DA = {}
assert(loadfile("Vocabulary.lua"))("DwarvenAccent", DA)
assert(loadfile("Core.lua"))("DwarvenAccent", DA)
local settings = DA.NewSettings()
local samples = {
    "I don't know where you're going, my friend.",
    "Well, that's a pretty good reason. Thanks for your help!",
    "((OOC: we meet at eight)) Don't worry about it, I know the way.",
    "Look at this |cff0070dd|Hitem:123:0|h[Very Pretty Sword]|h|r, little friend!",
    "Aye, I'll see you tomorrow, friend.",
}
local runs = 10000
local start = os.clock()
local changes = 0
for i = 1, runs do
    local _, n = DA.Transform(samples[(i - 1) % #samples + 1], settings)
    changes = changes + n
end
local elapsed = os.clock() - start
print(string.format("BENCH: %d messages / %.3fs (~%.0f messages/sec), %d substitutions",
    runs, elapsed, elapsed > 0 and runs / elapsed or 0, changes))
