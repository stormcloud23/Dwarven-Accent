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
eq(DA.Transform("I don't know, my friend. You're right.", db), "Ah dinnae ken, ma freend. Ye're right.", "balanced only enables eligible tiers")
eq(DA.Transform("I don't know, friend!", { preset = "Subtle" }), "Ah dinnae ken, friend!", "subtle")
eq(DA.Transform("I don't know. I don't know. I don't know.", { preset = "Subtle" }),
    "Ah dinnae ken. Ah dinnae ken. I don't know.", "message budget")
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
    "friend, fash and bother", "ambiguous vocabulary restricted to Heavy")
eq(transform("hello, PRETTY flower!"), "hello, BONNIE flower!", "uppercase phrase casing")
local allAfter, total = DA.Transform("I don't know. I don't know. I don't know.", { preset = "Subtle" })
eq(allAfter, "Ah dinnae ken. Ah dinnae ken. I don't know.", "unchanged suffix once limit reached")
eq(total, 2, "change count returned to UI")
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
print("PASS: additional 1.2 regressions (" .. count .. " total translation assertions)")
