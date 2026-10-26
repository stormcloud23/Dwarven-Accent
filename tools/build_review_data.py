#!/usr/bin/env python3
"""Regenerate GitHub Pages vocabulary and phrase data from the actual Lua sources.

No Python dependencies. Run: python3 tools/build_review_data.py
Check drift: python3 tools/build_review_data.py --check
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
CORE = (ROOT / 'Core.lua').read_text(encoding='utf-8')
VOCAB = (ROOT / 'Vocabulary.lua').read_text(encoding='utf-8')
RULE_RE = re.compile(r'^Add\("([^"]+)",\s*(\d+),\s*"([^"]+)",\s*"([^"]+)"(?:,\s*"([^"]+)")?\)', re.M)
TABLE_NAMES = (
    'APPEARANCE_NOUNS','APPEARANCE_MODIFIERS','EMPHASIS_ADJECTIVES',
    'CRAZY_NOUNS','FASH_OBJECTS','MAN_VERB_FOLLOWERS','BODY_PART_PRECEDERS',
    'NO_DETERMINER_NOUNS','NO_REPLY_FOLLOWERS',
)

def generate():
    rules = [dict(category=m[0], tier=int(m[1]), source=m[2], replacement=m[3], context=m[4] or None)
             for m in RULE_RE.findall(VOCAB)]
    assert len(rules) >= 100, f'Unexpected vocabulary: {len(rules)} rules'
    assert len({r['source'] for r in rules}) == len(rules), 'Duplicate source'
    categories = [dict(id=m[0], label=m[1]) for m in re.findall(r'\{ id = "([^"]+)", label = "([^"]+)" \}', VOCAB)]
    assert len(categories) == 7
    presets = {name: dict(tier=int(tier), limit=int(limit))
               for name, tier, limit in re.findall(r'(Subtle|Balanced|Heavy)\s*=\s*\{ tier = (\d+), limit = (\d+) \}', CORE)}
    assert len(presets) == 3
    tables = {}
    for name in TABLE_NAMES:
        m = re.search(r'local '+name+r'\s*=\s*\{(.*?)\n\}', CORE, re.S)
        assert m, f'Missing context table {name}'
        keys = re.findall(r'(?:\["([^"]+)"\]|([A-Za-z_][A-Za-z_0-9]*))\s*=\s*true', m[1])
        tables[name] = [a or b for a, b in keys]
        assert tables[name], f'Empty context table {name}'
    source_hash = hashlib.sha256((CORE+'\n'+VOCAB).encode('utf-8')).hexdigest()[:16]
    phrases = []
    for i, line in enumerate((ROOT / 'tools/phrases.tsv').read_text(encoding='utf-8').splitlines(), 1):
        if not line or line.startswith('#'):
            continue
        category, separator, phrase = line.partition('\t')
        if not separator or not phrase or '\t' in phrase:
            raise ValueError(f'Invalid phrase at {i}: {line!r}')
        phrases.append(dict(id='p'+str(len(phrases)+1).zfill(3), category=category, text=phrase))
    assert len(phrases) >= 200, f'Not enough phrases: {len(phrases)}'
    assert len({p['text'] for p in phrases}) == len(phrases), 'Repeated phrase'
    payload = dict(version='1.3', sourceHash=source_hash, rules=rules, presets=presets,
                   categories=categories, contexts=tables, phrases=phrases)
    return ('/* GENERATED from Core.lua, Vocabulary.lua and tools/phrases.tsv.\n'
            '   Do not edit. Run: python3 tools/build_review_data.py */\n'
            'window.DWARVEN_DATA = ' + json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + ';\n')

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    target = ROOT / 'docs/data.js'
    output = generate()
    if args.check:
        if not target.exists() or target.read_text(encoding='utf-8') != output:
            sys.exit('ERROR: docs/data.js is stale; run python3 tools/build_review_data.py')
        print('PASS: web data matches current Lua engine, vocabulary and phrase library')
    else:
        target.write_text(output, encoding='utf-8')
        print('Generated', target.relative_to(ROOT))
