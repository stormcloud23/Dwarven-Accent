'use strict';
const assert=require('node:assert/strict');
const {spawnSync}=require('node:child_process');
const fs=require('node:fs');
const path=require('node:path');
const root=path.join(__dirname,'..');
process.chdir(root);
global.window=global;
require(path.join(root,'docs/data.js'));
const engine=require(path.join(root,'docs/engine.js'));
const generated=global.DWARVEN_DATA;
const phraseFile=fs.readFileSync('tools/phrases.tsv','utf8');
const fromTsv=phraseFile.split(/\r?\n/).filter(x=>x && !x.startsWith('#')).map(x=>x.slice(x.indexOf('\t')+1));
assert.deepEqual(generated.phrases.map(p=>p.text),fromTsv,'Web corpus must equal TSV source');

// The library represents ordinary English before accent conversion.
 // Already-accented input hides missing or awkward rewrite behavior.
 // Protected item/spell names intentionally retain their exact wording.
const accentWords = /\b(?:lad|lads|lass|lasses|lassy|laddy|bonnie|wee|aye|nae|naw|och|ken|dinnae|cannae|fash|freend|numpty|barmy|daft|shite|aboot|ower|yersel|yer)\b/i;
for (const entry of generated.phrases) {
    if (entry.category !== 'Protected text') {
        assert.doesNotMatch(entry.text,accentWords,
            `Phrase ${entry.id} should start in ordinary English, not pretranslated dialect`);
    }
}
assert.ok(generated.phrases.some(p=>p.category==='Protected text' && p.text.includes('[The Pretty Lass]')),
    'Protected item-name example must remain intact');
assert.ok(generated.phrases.some(p=>p.text==='Good evening, boys and girls.'),
    'Greetings must contain untranslated boys and girls');

assert.equal(generated.rules.length,107,'Expected complete vocabulary');
const edges = [
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
    "NO, I WON'T",
];
const all=[...fromTsv,...edges];
const lua=spawnSync(process.env.LUA_BIN||'lua5.1',['tests/review_oracle.lua'],{encoding:'utf8',cwd:root});
if(lua.status!==0)throw Error(`Lua oracle failed: ${lua.stderr||lua.stdout}`);
let total=0;
for(const line of lua.stdout.trim().split(/\r?\n/)){
    const match=/^(\d+)\t(Subtle|Balanced|Heavy|Restricted)\t(\d+)\t(.*)$/.exec(line);
    assert.ok(match,'Invalid Lua oracle row: '+line);
    const [,index,name,count,expected]=match;
    const options=name==='Restricted'?{preset:'Heavy',maxChanges:1,disabledRules:{little:true},categories:{slang:false}}:{preset:name};
    const result=engine.transform(all[Number(index)-1],options);
    assert.equal(result.text,expected,`Translation mismatch in ${name} sample #${index}: ${all[Number(index)-1]}`);
    assert.equal(result.count,Number(count),`Change count mismatch in ${name} sample #${index}`);
    assert.equal(result.parts.map(p=>p.text).join(''),result.text,'Highlight text must equal translation');
    total++;
}
assert.equal(total,all.length*4,'Must compare every corpus and edge phrase against four settings');
assert.equal(engine.transform("I don't know",{preset:'Balanced'}).text,'Ah dinnae ken');
assert.equal(engine.transform('that’s a pretty flower',{preset:'Heavy'}).text,'that’s a bonnie flower');
// Browser-only full-passage review mode must not change default in-game parity.
const repeated = ("I don't know. ").repeat(32).trim();
for (const [name,cap] of [['Subtle',32],['Balanced',32],['Heavy',32]]) {
    const game=engine.transform(repeated,{preset:name});
    const full=engine.transform(repeated,{preset:name,reviewUnlimited:true});
    assert.equal(game.count,cap,`${name} in-game default substitution count`);
    assert.equal(full.count,32,`${name} full passage reaches the last sentence`);
    assert.ok(full.text.endsWith('Ah dinnae ken.'),`${name} last sentence is translated`);
    assert.equal(full.parts.map(p=>p.text).join(''),full.text,'Full mode highlights are exact');
}
assert.equal(engine.transform('my friend and friend',{preset:'Balanced'}).text,
  'my friend and friend','Balanced never translates friend or my friend to freend');
assert.equal(engine.transform('my friend and friend',{preset:'Heavy'}).text,
  'ma freend and freend','Heavy translates both friend expressions');
assert.equal(engine.transform(repeated,{preset:'Heavy',maxChanges:4}).count,4,
  'Manual Heavy cap still takes precedence over unlimited default');
const withMarkup = ("I don't know. ").repeat(8) + '((I don\'t know.)) [you] ' + ("I don't know. ").repeat(8);
const fullMarkup=engine.transform(withMarkup,{preset:'Balanced',reviewUnlimited:true});
assert.equal(fullMarkup.count,16,'OOC and bracketed text remain protected in full review');
assert.ok(fullMarkup.text.includes('((I don\'t know.)) [you]'));
assert.equal(engine.transform(repeated,{preset:'Balanced',reviewUnlimited:false}).count,32,
  'Without a manual cap, ordinary browser mode also translates the full text');
for (const name of ['Subtle','Balanced','Heavy']) {
  assert.equal(engine.transform(repeated,{preset:name,maxChanges:10}).count,10,
    name+' optional custom cap limits changes');
}
assert.equal(engine.transform(repeated,{preset:'Balanced',maxChanges:1,reviewUnlimited:true}).count,32,
  'Full review mode bypasses custom cap as well');
console.log('PASS: browser-only full-passage mode, in-game caps, markup, and final-sentence coverage');
console.log(`PASS: ${total} browser/Lua parity comparisons (${fromTsv.length} RP dialogues, ${edges.length} edge cases, 4 settings each)`);
