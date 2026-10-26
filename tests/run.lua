-- Run from repository root: lua5.1 tests/run.lua
local DA = {}
assert(loadfile("Vocabulary.lua"))("DwarvenAccent", DA)
assert(loadfile("Core.lua"))("DwarvenAccent", DA)
assert(loadfile("Options.lua"))
assert(loadfile("DwarvenAccent.lua"))

local count = 0
local function eq(actual, expected, title)
    count = count + 1
    if actual ~= expected then
        error((title or "test") .. "\n expected: " .. tostring(expected) .. "\n      got: " .. tostring(actual), 2)
    end
end
local db = DA.NewSettings()
local function transform(s, overrides)
    local settings = DA.NewSettings()
    settings.preset = "Heavy"
    settings.maxChanges = 20
    if overrides then for key, val in pairs(overrides) do settings[key] = val end end
    return DA.Transform(s, settings)
end

-- Curated rule precedence, word boundaries, casing and single-pass behavior.
eq(transform("I don't know"), "Ah dinnae ken", "phrase has priority")
eq(transform("I don't know, you know."), "Ah dinnae ken, ye ken.", "no cascading")
eq(transform("I do not know"), "Ah dinnae ken", "longest phrase")
eq(transform("You're my friend."), "Ye're ma freend.", "initial capital")
eq(transform("I am here"), "Ah am here", "standalone I")
eq(transform("NO, I WON'T"), "NAW, Ah WINNAE", "caps but not I")
eq(transform("nobody is here"), "nobody is here", "whole words")
eq(transform("no!"), "naw!", "no is whole word")
eq(transform("pretty sure and pretty lass"), "pretty sure and bonnie lass", "context")
eq(transform("I don't know"), "Ah dinnae ken", "not reprocessed")

-- Keep chat markup and OOC text untouched.
eq(transform("[You are my friend] you are my friend"), "[You are my friend] ye are ma freend", "brackets")
eq(transform("[A [nested] friend] friend"), "[A [nested] friend] freend", "balanced brackets")
eq(transform("((I don't know)) I don't know"), "((I don't know)) Ah dinnae ken", "OOC")
eq(transform("I don't know ((you are a friend"), "Ah dinnae ken ((you are a friend", "unclosed OOC")
eq(transform("see https://example.com/you/friend and you"), "see https://example.com/you/friend and ye", "URL")
eq(transform("www.example.com/friend and friend"), "www.example.com/friend and freend", "www URL")
eq(transform("[friend] friend"), "[friend] freend", "item text")
local link = "|cff0070dd|Hitem:123:0|h[Friend of You]|h|r"
eq(transform("My friend " .. link .. " and you"), "Ma freend " .. link .. " and ye", "whole hyperlink")
eq(transform("|Hspell:1|h[You Know]|h friend"), "|Hspell:1|h[You Know]|h freend", "no-color hyperlink")
eq(transform("/say you are my friend"), "/say you are my friend", "slash commands")

-- Presets, limits and per-rule/category opt-outs.
eq(DA.Transform("I don't know, my friend. You're right.", db), "Ah dinnae ken, my friend. Ye're right.", "balanced leaves friend unchanged")
eq(DA.Transform("I don't know, friend!", { preset = "Subtle" }), "Ah dinnae ken, friend!", "subtle")
eq(DA.Transform("I don't know. I don't know. I don't know.", { preset = "Subtle" }),
    "Ah dinnae ken. Ah dinnae ken. Ah dinnae ken.", "subtle now uncapped")
eq(transform("yes, little friend", { disabledRules = { ["little"] = true } }), "aye, little freend", "individual toggle")
eq(transform("yes, little friend", { categories = { slang = false } }), "yes, little friend", "category toggle")
eq(transform("yes, little friend", { enabled = false }), "yes, little friend", "disabled")
eq(DA.Transform(nil, db), nil, "nil input")
eq(DA.Transform("", db), "", "empty input")
eq(DA.ValidateSettings({ preset = "invalid", maxChanges = -10 }).preset, "Balanced", "settings validation")

local unique = {}
for _, rule in ipairs(DA.Rules) do
    assert(not unique[rule.source], "duplicate source: " .. rule.source)
    unique[rule.source] = true
    assert(rule.source == rule.source:lower(), "source must be lowercase")
    assert(rule.tier >= 1 and rule.tier <= 3)
end
print("PASS: " .. count .. " functional assertions, " .. #DA.Rules .. " unique vocabulary rules")

-- Advanced 1.2 regression cases: conservative phrasing and safe chat markup.
eq(transform("pretty fast, pretty sure, pretty far"),
    "pretty fast, pretty sure, pretty far", "pretty is usually an adverb")
eq(transform("a pretty flower and a pretty view"),
    "a bonnie flower and a bonnie view", "pretty adjective requires safe noun")
eq(transform("oh, I don't know"), "och, Ah dinnae ken", "och is optional flavor")
eq(DA.Transform("Oh, I don't know", db), "Och, Ah dinnae ken", "balanced flavor")
eq(DA.Transform("friend, worry and bother", db),
    "friend, worry and bother", "avoid standalone non-idiomatic fash")
eq(transform("hello, PRETTY flower!"), "hello, BONNIE flower!", "uppercase phrase casing")
local allAfter, total = DA.Transform("I don't know. I don't know. I don't know.", { preset = "Subtle" })
eq(allAfter, "Ah dinnae ken. Ah dinnae ken. Ah dinnae ken.", "all sentences translated by default")
eq(total, 3, "uncapped change count returned to UI")
local noChanges, zero = DA.Transform("www.example.org/pretty?who=you", db)
eq(noChanges, "www.example.org/pretty?who=you", "URLs preserved")
eq(zero, 0, "protected-only text count")
local markup = "|cffa335ee|Hitem:123:0|h[Pretty You]|h|r"
eq(transform("you " .. markup .. " little"), "ye " .. markup .. " wee", "colored link unchanged")
eq(transform("you |TInterface\\Icons\\INV_Misc_QuestionMark:0|t little"),
    "ye |TInterface\\Icons\\INV_Misc_QuestionMark:0|t wee", "texture escape")
eq(transform("you |A:Ping:0:0|a little"), "ye |A:Ping:0:0|a wee", "atlas escape")
eq(transform("((some OOC [you])) little"), "((some OOC [you])) wee", "mixed protected spans")
eq(transform("[unclosed you little"), "[unclosed you little", "unfinished bracket safe")
eq(transform("you || little"), "ye || wee", "escaped pipe sequence safe")
eq(transform("hello there", { maxChanges = 0 }), "hello there", "no unnecessary changes")
eq(DA.ValidateSettings({ maxChanges = 100, preset = "Oops" }).maxChanges, 0, "bad max limit")
eq(DA.ValidateSettings({ disabledRules = "bad", categories = "bad" }).categories ~= nil,
    true, "invalid saved table repaired")

-- Required rule metadata and stable uniqueness.
for _, rule in ipairs(DA.Rules) do
    assert(type(rule.replacement) == "string" and #rule.replacement > 0)
    assert(type(rule.category) == "string" and #rule.category > 0)
    assert(type(rule.length) == "number" and rule.length == #rule.source)
end
-- Advanced 1.3: contextual vocabulary behavior and conservative fallbacks.
-- The source word must remain available if surrounding words do not justify a translation.
eq(transform("a pretty little village"), "a bonnie wee village", "visual adjective before modifier")
eq(transform("a pretty little problem"), "a pretty wee problem", "not a visual description")
eq(transform("a pretty small old house"), "a bonnie small old house", "two safe modifiers")
eq(transform("pretty good, pretty sure, pretty tired"),
    "pretty good, pretty sure, pretty knackered", "degree adverbs remain intact")
eq(transform("a beautiful view"), "a bonnie view", "visual beauty")
eq(transform("a beautiful solution"), "a beautiful solution", "figurative beauty conservatively skipped")
eq(transform("a beautiful little garden"), "a bonnie wee garden", "beautiful visual noun")
eq(transform("very good, very much, very cold"),
    "bloody good, very much, bloody cold", "selective intensifier")
eq(transform("very, very good"), "very, bloody good", "punctuation does not join context")
eq(transform("a crazy plan"), "a barmy plan", "crazy noun")
eq(transform("that's crazy!"), "that's barmy!", "crazy stand-alone description")
eq(transform("crazy good, crazy about you"),
    "crazy good, crazy aboot ye", "crazy as degree or idiom is not changed")
eq(transform("please don't worry"), "please dinnae fash", "idiom prioritized")
eq(transform("worry yourself, don't trouble me"),
    "fash yersel, dinnae fash me", "fash takes personal object")
eq(transform("I worry about trouble"), "Ah worry aboot trouble", "no noun or intransitive fash")
eq(transform("sorry to bother you"), "sorry to fash ye", "transitive bother becomes fash")
eq(transform("don't bother to come"), "dinnae bother to come", "bother to is not transitive")
eq(transform("man the cannons!"), "man the cannons!", "man verb protected")
eq(transform("man your station, my man"), "man yer station, my lad", "verb vs noun man")
eq(transform("that's a pretty flower"), "that's a bonnie flower",
    "that contraction must not become double apostrophe")
eq(transform("that’s a pretty flower"), "that’s a bonnie flower",
    "curly apostrophe contraction protected")
eq(transform("that man"), "tha' lad", "bare demonstrative still converts")

eq(transform("No! No, thanks. No time. No idea."),
    "Naw! Naw, cheers. Nae time. Nae idea.", "naw reply versus nae determiner")
eq(transform("no one, no longer, no lantern"),
    "no one, no longer, no lantern", "ambiguous no stays unchanged")
eq(transform("I've got no gold"), "Ah've got nae gold", "no as determiner")
eq(transform("my ass and a stubborn ass"),
    "my arse and a stubborn ass", "arse body context only")
eq(transform("what a smart ass!"), "what a smart arse!", "smart arse idiom")
eq(DA.Transform("I wanna go", { preset = "Balanced" }),
    "Ah want tae go", "wanna has grammatical replacement")
eq(DA.Transform("I have no idea", { preset = "Balanced" }),
    "Ah have no idea", "heavy-only no context not enabled by Balanced")
local phrasing, used = DA.Transform("pretty sure, you", { preset = "Heavy", maxChanges = 1 })
eq(phrasing, "pretty sure, ye", "rejected context never consumes substitution budget")
eq(used, 1, "only successful replacement counts")
eq(transform("((No idea, pretty lass)) no time"),
    "((No idea, pretty lass)) nae time", "OOC takes priority over context")
local validContext = {
    appearance = true, intensifier = true, crazy_description = true,
    fash_verb = true, man_noun = true, body_part = true, no_form = true, bare_only = true,
}
local contextCount = 0
for _, rule in ipairs(DA.Rules) do
    if rule.context then
        assert(validContext[rule.context], "unknown rule context: " .. rule.context)
        contextCount = contextCount + 1
    end
end
assert(contextCount >= 10, "not enough context-tagged ambiguous entries")
-- All tiers default to unlimited; the vocabulary tiers still restrict rule eligibility.
eq(DA.Transform("my friend and friend", {preset="Balanced"}),
    "my friend and friend", "balanced friend expressions untouched")
eq(DA.Transform("my friend and friend", {preset="Subtle"}),
    "my friend and friend", "subtle friend expressions untouched")
eq(DA.Transform("my friend and friend", {preset="Heavy"}),
    "ma freend and freend", "heavy friend expressions enabled")
local repeatedFriends = string.rep("friend ", 12)
local heavyResult, heavyCount = DA.Transform(repeatedFriends, {preset="Heavy"})
eq(heavyResult, string.rep("freend ", 12), "heavy continues past seven changes")
eq(heavyCount, 12, "heavy counts all changes without a cap")
local manualResult, manualCount = DA.Transform(repeatedFriends, {preset="Heavy", maxChanges=4})
eq(manualResult, string.rep("freend ", 4) .. string.rep("friend ", 8),
    "manual heavy substitution cap still works")
eq(manualCount, 4, "heavy manual limit counts four changes")
local balancedResult, balancedCount = DA.Transform(string.rep("little ", 12), {preset="Balanced"})
eq(balancedCount, 12, "balanced now processes the entire message")
eq(balancedResult, string.rep("wee ", 12),
    "balanced preserves no untranslated tail")
for _, name in ipairs({"Subtle", "Balanced", "Heavy"}) do
    local presetResult, presetCount = DA.Transform(repeatedFriends, {preset=name})
    if name == "Heavy" then
        eq(presetResult, string.rep("freend ", 12), "heavy-only friend translation")
        eq(presetCount, 12, "heavy friend substitution count")
    else
        eq(presetResult, repeatedFriends, name .. " still excludes heavy-only words")
        eq(presetCount, 0, name .. " still excludes heavy-only words from count")
    end
    local longResult, longCount = DA.Transform(string.rep("little ", 12), {preset=name})
    eq(longResult, string.rep("wee ", 12), name .. " rewrites the full message")
    eq(longCount, 12, name .. " has no default cap")
    local cappedResult, cappedCount = DA.Transform(string.rep("little ", 12), {preset=name, maxChanges=4})
    eq(cappedResult, string.rep("wee ", 4) .. string.rep("little ", 8), name .. " respects manual cap")
    eq(cappedCount, 4, name .. " reports capped substitution count")
    assert(DA.Presets[name].limit == 0, name .. " preset must default to unlimited")
end
print("PASS: Advanced 1.3 translation suite (" .. count .. " assertions; "
    .. contextCount .. " context-aware rules)")
