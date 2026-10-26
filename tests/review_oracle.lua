-- Test oracle for GitHub Pages: use the real Lua addon, never a JS approximation.
local DA = {}
assert(loadfile('Vocabulary.lua'))('DwarvenAccent', DA)
assert(loadfile('Core.lua'))('DwarvenAccent', DA)
local samples = {}
local f = assert(io.open('tools/phrases.tsv', 'r'))
for line in f:lines() do
    if line:sub(1, 1) ~= '#' and line ~= '' then
        local _, _, category, phrase = line:find('^([^\t]+)\t(.+)$')
        assert(phrase, 'Malformed phrase TSV')
        samples[#samples + 1] = phrase
    end
end
f:close()
-- Corpus-aligned extras exercise invisible markup, punctuation, and precise rule controls.
local edge = {
    '[[you] friend] yes',
    'You |TInterface\\Icons\\INV_Misc_QuestionMark:0|t are my friend',
    'You |A:Ping:0:0|a know',
    'You |cff0070dd|Hitem:123|h[My Little Friend]|h|r know',
    "YOU KNOW THAT'S A PRETTY FLOWER",
    'No, no time, no one, no money!',
    'my ass and a stubborn ass',
    '((unfinished OOC my friend',
    'I do not know but you do know',
    'www.example.com/you?name=pretty friend',
    'that’s that friend',
    '/say do you know what your friend thinks?',
    'very good! very much! pretty sure!',
    'pretty small old house, pretty small bad idea',
    'NO, I WON\'T',
}
for _, item in ipairs(edge) do samples[#samples + 1] = item end
for i, phrase in ipairs(samples) do
    for _, preset in ipairs({'Subtle','Balanced','Heavy'}) do
        local result, changes = DA.Transform(phrase, {preset=preset})
        assert(not result:find('[\t\n\r]'), 'Fixture must have one line: ' .. phrase)
        io.write(i, '\t', preset, '\t', changes, '\t', result, '\n')
    end
end
-- Dedicated config cases, not just presets.
for i, phrase in ipairs(samples) do
    local result, changes = DA.Transform(phrase, {
        preset='Heavy', maxChanges=1, disabledRules={little=true}, categories={slang=false}
    })
    io.write(i, '\t', 'Restricted', '\t', changes, '\t', result, '\n')
end
