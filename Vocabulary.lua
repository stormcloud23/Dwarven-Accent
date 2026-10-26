-- Dwarven Accent Advanced 1.2: curated vocabulary, from the original 1.0 rules.
-- Tier 1 = Subtle; tier 2 = Balanced; tier 3 = Heavy only.
-- Every source string is a stable identifier for the individual rule toggle.
local _, DA = ...

DA.Categories = {
    { id = "phrases", label = "Phrases & greetings" },
    { id = "contractions", label = "Contractions" },
    { id = "pronouns", label = "Pronouns" },
    { id = "slang", label = "Scots vocabulary" },
    { id = "everyday", label = "Everyday words" },
    { id = "exclamations", label = "Exclamations" },
    { id = "strong", label = "Strong language" },
}

local entries = {}
local function Add(category, tier, source, replacement)
    entries[#entries + 1] = {
        category = category,
        tier = tier,
        source = source,
        replacement = replacement,
    }
end

-- Idioms and multiword phrases take precedence over individual words.
Add("phrases", 1, "i don't know", "ah dinnae ken")
Add("phrases", 1, "i dont know", "ah dinnae ken")
Add("phrases", 1, "i do not know", "ah dinnae ken")
Add("phrases", 1, "don't worry", "dinnae fash")
Add("phrases", 1, "dont worry", "dinnae fash")
Add("phrases", 1, "do not worry", "dinnae fash")
Add("phrases", 1, "thank you", "thank ye")
Add("phrases", 1, "thanks", "cheers")
Add("phrases", 2, "how are you", "how are ye")
Add("phrases", 2, "what are you", "whit are ye")
Add("phrases", 2, "come here", "come o'er here")
Add("phrases", 2, "my friend", "ma freend")
Add("phrases", 3, "this sucks", "tha's a fine mess")
Add("phrases", 3, "out of", "oot o'")

Add("contractions", 1, "don't", "dinnae")
Add("contractions", 1, "doesn't", "disnae")
Add("contractions", 1, "didn't", "didnae")
Add("contractions", 1, "didnt", "didnae")
Add("contractions", 1, "did not", "didnae")
Add("contractions", 1, "isn't", "isnae")
Add("contractions", 1, "isnt", "isnae")
Add("contractions", 1, "can't", "cannae")
Add("contractions", 1, "cant", "cannae")
Add("contractions", 1, "cannot", "cannae")
Add("contractions", 1, "can not", "cannae")
Add("contractions", 1, "won't", "winnae")
Add("contractions", 1, "wont", "winnae")
Add("contractions", 1, "will not", "winnae")
Add("contractions", 2, "haven't", "haenae")
Add("contractions", 2, "havent", "haenae")
Add("contractions", 2, "have not", "haenae")
Add("contractions", 2, "hasn't", "hasnae")
Add("contractions", 2, "hasnt", "hasnae")
Add("contractions", 2, "has not", "hasnae")
Add("contractions", 2, "hadn't", "hadnae")
Add("contractions", 2, "hadnt", "hadnae")
Add("contractions", 2, "had not", "hadnae")
Add("contractions", 2, "wasn't", "wisnae")
Add("contractions", 2, "wasnt", "wisnae")
Add("contractions", 2, "was not", "wisnae")
Add("contractions", 2, "aren't", "arenae")
Add("contractions", 2, "arent", "arenae")
Add("contractions", 2, "are not", "arenae")
Add("contractions", 2, "weren't", "werenae")
Add("contractions", 2, "werent", "werenae")
Add("contractions", 2, "were not", "werenae")
Add("contractions", 2, "wouldn't", "wouldnae")
Add("contractions", 2, "wouldnt", "wouldnae")
Add("contractions", 2, "would not", "wouldnae")
Add("contractions", 2, "couldn't", "couldnae")
Add("contractions", 2, "couldnt", "couldnae")
Add("contractions", 2, "could not", "couldnae")
Add("contractions", 2, "shouldn't", "shouldnae")
Add("contractions", 2, "shouldnt", "shouldnae")
Add("contractions", 2, "should not", "shouldnae")

Add("pronouns", 1, "you're", "ye're")
Add("pronouns", 1, "youre", "ye're")
Add("pronouns", 1, "you've", "ye've")
Add("pronouns", 1, "youve", "ye've")
Add("pronouns", 1, "you'll", "ye'll")
Add("pronouns", 1, "youll", "ye'll")
Add("pronouns", 2, "yourself", "yersel")
Add("pronouns", 2, "do you", "d'ye")
Add("pronouns", 2, "you", "ye")
Add("pronouns", 2, "your", "yer")
Add("pronouns", 2, "i", "ah")
Add("pronouns", 3, "them", "thae")

Add("slang", 1, "little", "wee")
Add("slang", 1, "know", "ken")
Add("slang", 1, "yes", "aye")
Add("slang", 1, "yeah", "aye")
Add("slang", 2, "stupid", "daft")
Add("slang", 2, "dumb", "daft")
Add("slang", 2, "silly", "daft")
Add("slang", 2, "idiot", "numpty")
Add("slang", 2, "moron", "numpty")
Add("slang", 2, "before", "afore")
Add("slang", 2, "crazy", "barmy")
Add("slang", 2, "tired", "knackered")
Add("slang", 2, "worry", "fash")
Add("slang", 3, "trouble", "fash")
Add("slang", 3, "bother", "fash")
Add("slang", 3, "pretty", "bonnie")
Add("slang", 2, "beautiful", "bonnie")
Add("slang", 3, "friend", "freend")
Add("slang", 3, "nothing", "naething")
Add("slang", 3, "man", "lad")
Add("slang", 3, "boy", "laddy")
Add("slang", 3, "woman", "lass")
Add("slang", 3, "girl", "lassy")

Add("everyday", 2, "with", "wi'")
Add("everyday", 2, "without", "wi'oot")
Add("everyday", 2, "over", "ower")
Add("everyday", 2, "gonna", "gonnae")
Add("everyday", 2, "gotta", "hae tae")
Add("everyday", 2, "wanna", "fancy tae")
Add("everyday", 2, "kinda", "sortae")
Add("everyday", 3, "that", "tha'")
Add("everyday", 3, "about", "aboot")
Add("everyday", 3, "because", "cause")
Add("everyday", 3, "though", "tho")
Add("everyday", 3, "of", "o'")
Add("strong", 3, "very", "bloody")
Add("everyday", 3, "no", "naw")

Add("exclamations", 2, "oh", "och")
Add("strong", 3, "shit", "shite")
Add("strong", 3, "ass", "arse")

DA.Rules = entries
