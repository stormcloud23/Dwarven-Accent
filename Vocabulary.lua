-- Imperial Accent: Reikland-flavored ENGLISH, not word-for-word German.
-- The Advanced engine is unchanged; vocabulary provides restrained code-switching.
local _, DA = ...
DA.Categories = {
 {id="phrases",label="Greetings & Imperial idioms"},
 {id="contractions",label="Contractions (reserved)"},
 {id="pronouns",label="Ranks & forms of address"},
 {id="slang",label="Reikland vocabulary"},
 {id="everyday",label="Tavern & military terms"},
 {id="exclamations",label="Exclamations & oaths"},
 {id="strong",label="Strong language"},
}
local entries={}
local function Add(category,tier,source,replacement,context)
 entries[#entries+1]={category=category,tier=tier,source=source,replacement=replacement,context=context}
end

-- Tier 1: phrases
Add("phrases",1,"good morning","guten Morgen")
Add("phrases",1,"good evening","guten Abend")
Add("phrases",1,"good day","guten Tag")
Add("phrases",1,"good night","gute Nacht")
Add("phrases",1,"thank you","danke")
Add("phrases",1,"many thanks","much obliged")
Add("phrases",1,"you're welcome","think nothing of it")
Add("phrases",1,"farewell","fare thee well")
Add("phrases",1,"goodbye","farewell")
Add("phrases",1,"well met","well met, mein Freund")
Add("phrases",1,"my friend","mein Freund")
Add("phrases",1,"my friends","meine Freunde")
Add("phrases",1,"of course","ja, of course")
Add("phrases",1,"very well","ja, very well")

-- Tier 1: slang
Add("slang",1,"yes","ja")
Add("slang",1,"yeah","ja")
Add("slang",1,"no","nein","imperial_no_reply")
Add("slang",1,"thanks","danke")
Add("slang",1,"hello","greetings")
Add("slang",1,"friend","Freund")
Add("slang",1,"friends","Freunde")

-- Tier 1: pronouns
Add("pronouns",1,"sir","mein Herr")
Add("pronouns",1,"madam","gnädige Frau")
Add("pronouns",1,"gentlemen","Herren")

-- Tier 1: exclamations
Add("exclamations",1,"damn","verdammt")

-- Tier 2: phrases
Add("phrases",2,"watch out","mind yourself")
Add("phrases",2,"be careful","have a care")
Add("phrases",2,"hurry up","make haste")
Add("phrases",2,"let's go","come, then")
Add("phrases",2,"well done","well struck")
Add("phrases",2,"good luck","Sigmar guide you")
Add("phrases",2,"at once","with all haste")
Add("phrases",2,"stand firm","hold fast")
Add("phrases",2,"hold the line","hold the line, lads")
Add("phrases",2,"for the emperor","for the Emperor")
Add("phrases",2,"for the empire","for the Empire")
Add("phrases",2,"by sigmar","by Sigmar")
Add("phrases",2,"by god","by Sigmar")
Add("phrases",2,"thank god","thank Sigmar")
Add("phrases",2,"god help us","Sigmar preserve us")
Add("phrases",2,"what the hell","what in Sigmar's name")
Add("phrases",2,"what on earth","what in Sigmar's name")
Add("phrases",2,"come here","come here, schnell")
Add("phrases",2,"don't worry","keep your nerve")
Add("phrases",2,"do not worry","keep your nerve")
Add("phrases",2,"dont worry","keep your nerve")
Add("phrases",2,"my lord","mein lord")
Add("phrases",2,"my lady","mein lady")

-- Tier 2: pronouns
Add("pronouns",2,"captain","Hauptmann")
Add("pronouns",2,"commander","Kommandant")
Add("pronouns",2,"comrade","Kamerad")
Add("pronouns",2,"comrades","Kameraden")
Add("pronouns",2,"sergeant","Feldwebel")
Add("pronouns",2,"master","Meister")

-- Tier 2: slang
Add("slang",2,"idiot","Dummkopf")
Add("slang",2,"idiots","Dummköpfe")
Add("slang",2,"quickly","schnell")
Add("slang",2,"nonsense","Unsinn")
Add("slang",2,"mercenary","lands knecht")
Add("slang",2,"mercenaries","landsknechts")

-- Tier 2: everyday
Add("everyday",2,"tavern","Wirtshaus")
Add("everyday",2,"inn","Gasthaus")
Add("everyday",2,"beer","Bier")
Add("everyday",2,"ale","Bier")

-- Tier 2: exclamations
Add("exclamations",2,"oh no","ach, nein")
Add("exclamations",2,"oh","ach")
Add("exclamations",2,"damn it","verdammt")

-- Tier 2: strong
Add("strong",2,"damned","verdamned")

-- Tier 3: phrases
Add("phrases",3,"i don't know","I've not the faintest notion")
Add("phrases",3,"i do not know","I've not the faintest notion")
Add("phrases",3,"i dont know","I've not the faintest notion")
Add("phrases",3,"i understand","I understand, ja")
Add("phrases",3,"i agree","ja, I agree")
Add("phrases",3,"do you understand","do you understand, Kamerad")
Add("phrases",3,"what is that","what in Sigmar's name is that")
Add("phrases",3,"what is this","what in Sigmar's name is this")
Add("phrases",3,"where are you","where have you got to")
Add("phrases",3,"follow me","on me, Kameraden")
Add("phrases",3,"help me","lend me a hand")
Add("phrases",3,"get out","out with you")
Add("phrases",3,"to arms","to arms, for the Empire")
Add("phrases",3,"good hunting","good hunting, Kamerad")
Add("phrases",3,"hold your ground","stand your ground, by Sigmar")
Add("phrases",3,"we need help","we need reinforcements, schnell")
Add("phrases",3,"i swear","by my oath")
Add("phrases",3,"i promise","you have my word")
Add("phrases",3,"i'm ready","ready and waiting")
Add("phrases",3,"we are ready","we stand ready")
Add("phrases",3,"don't be afraid","keep your courage")
Add("phrases",3,"do not be afraid","keep your courage")
Add("phrases",3,"may god protect you","may Sigmar watch over you")
Add("phrases",3,"for god's sake","for Sigmar's sake")
Add("phrases",3,"good heavens","Sigmar preserve us")
Add("phrases",3,"my god","Sigmar preserve us")
Add("phrases",3,"what a mess","a fine bloody mess")

-- Tier 3: pronouns
Add("pronouns",3,"brother","Bruder")
Add("pronouns",3,"brothers","Brüder")
Add("pronouns",3,"sister","Schwester")
Add("pronouns",3,"sisters","Schwestern")

-- Tier 3: slang
Add("slang",3,"coward","Feigling")
Add("slang",3,"cowards","Feiglinge")
Add("slang",3,"witch","Hexe")
Add("slang",3,"witches","Hexen")
Add("slang",3,"foolish","damned foolish")

-- Tier 3: everyday
Add("everyday",3,"black powder","blackpowder")
Add("everyday",3,"gunpowder","blackpowder")

-- Tier 3: exclamations
Add("exclamations",3,"good grief","Sigmar preserve us")
Add("exclamations",3,"holy shit","by Sigmar's hammer")
Add("exclamations",3,"holy hell","by Sigmar's hammer")

-- Tier 3: strong

DA.Rules=entries
