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
console.log(`PASS: ${total} browser/Lua parity comparisons (${fromTsv.length} RP dialogues, ${edges.length} edge cases, 4 settings each)`);
