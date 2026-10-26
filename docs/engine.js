/* Browser port of the exact Advanced 1.3 Lua translation rules.
   Coverage is enforced by comparing ALL fixtures with the real Lua Core.lua in CI.
   Protected spans, optional caps, original-text context, and single-pass precedence
   intentionally mirror Core.lua. Never edit data.js by hand. */
(function (root) {
  'use strict';
  const D = root.DWARVEN_DATA;
  if (!D) throw new Error('Missing generated data.js');
  const sets = Object.fromEntries(Object.entries(D.contexts).map(([key, words]) => [key, new Set(words)]));
  const indexed = {};
  for (const rule of D.rules) {
    const first = rule.source[0];
    (indexed[first] ??= []).push({ ...rule, length: rule.source.length });
  }
  for (const rules of Object.values(indexed)) rules.sort((a,b) => b.length-a.length || a.tier-b.tier || a.source.localeCompare(b.source));
  const isWord = ch => /[A-Za-z0-9_]/.test(ch || '') && (ch || '').length === 1;
  const nextWord = (text, last) => /^\s+([A-Za-z]+)/.exec(text.slice(last))?.[1] || null;
  const previousWord = (text, first) => /([A-Za-z']+)\s*$/.exec(text.slice(0, first))?.[1] || null;
  function visualNoun(text, last) {
    let remain = text.slice(last);
    for (let j=0;j<3;j++) {
      const m = /^\s+([A-Za-z]+)/.exec(remain);
      if (!m) return false;
      if (sets.APPEARANCE_NOUNS.has(m[1])) return true;
      if (!sets.APPEARANCE_MODIFIERS.has(m[1])) return false;
      remain = remain.slice(m[0].length);
    }
    return false;
  }
  function contextReplacement(rule, lower, first, last) {
    if (!rule.context) return rule.replacement;
    const next = nextWord(lower, last);
    switch (rule.context) {
      case 'appearance': return visualNoun(lower,last) ? rule.replacement : null;
      case 'intensifier': return next && sets.EMPHASIS_ADJECTIVES.has(next) ? rule.replacement : null;
      case 'crazy_description': return !next || sets.CRAZY_NOUNS.has(next) ? rule.replacement : null;
      case 'fash_verb': return next && sets.FASH_OBJECTS.has(next) ? rule.replacement : null;
      case 'miss_address': {
        // Keep speech addresses, not 'miss the shot', 'I miss you' or 'a miss'.
        const before=lower.slice(0,first), after=lower.slice(last);
        const isPause=/^\s*[,!?.]/.test(after) || /^\s*$/.test(after);
        if (!isPause) return null;
        const prev=previousWord(lower,first);
        const greeting=['hello','hi','hey','greetings'].includes(prev);
        const afterComma=/,\s*$/.test(before);
        const atStart=/^\s*$/.test(before) && /^\s*,/.test(after);
        const polite=/(?:excuse|pardon)\s+me\s*$/.test(before);
        return (greeting || afterComma || atStart || polite) ? rule.replacement : null;
      }
      case 'man_noun': return !next || !sets.MAN_VERB_FOLLOWERS.has(next) ? rule.replacement : null;
      case 'bare_only': return (lower[last] !== "'" && lower[last] !== '’') ? rule.replacement : null;
      case 'body_part': { const prev = previousWord(lower,first); return prev && sets.BODY_PART_PRECEDERS.has(prev) ? rule.replacement : null; }
      case 'no_form':
        if (next && sets.NO_DETERMINER_NOUNS.has(next)) return 'nae';
        if (!next || sets.NO_REPLY_FOLLOWERS.has(next)) return 'naw';
        return null;
      default: return null;
    }
  }
  function matchCase(original, replacement) {
    if (original.length > 1 && /[A-Za-z]/.test(original) && original === original.toUpperCase()) return replacement.toUpperCase();
    if (/^[A-Z]/.test(original)) return replacement[0].toUpperCase() + replacement.slice(1);
    return replacement;
  }
  function protectedLength(text, position) {
    const rest = text.slice(position);
    const lead = rest[0];
    if (lead === '|') {
      const match = /^\|c[0-9a-fA-F]{8}\|H[\s\S]*?\|h[\s\S]*?\|h\|r/.exec(rest)
        || /^\|H[\s\S]*?\|h[\s\S]*?\|h/.exec(rest)
        || /^\|T[\s\S]*?\|t/.exec(rest)
        || /^\|A[\s\S]*?\|a/.exec(rest)
        || /^\|\|/.exec(rest);
      return match ? match[0].length : 0;
    }
    if (lead === '(' && rest[1] === '(') {
      const end = text.indexOf('))',position+2);
      return end < 0 ? rest.length : end+2-position;
    }
    if (lead === '[') {
      let depth=0;
      for (let i=0;i<rest.length;i++) {
        if (rest[i]==='[') depth++;
        else if (rest[i]===']') {
          depth--;
          if (depth===0) return i+1;
        }
      }
      return rest.length;
    }
    if ((lead==='h' && rest.slice(0,4)==='http') || (lead==='w' && rest.slice(0,4)==='www.')) {
      return (/^https?:\/\/[^\s]+/.exec(rest) || /^www\.[^\s]+/.exec(rest))?.[0].length || 0;
    }
    return 0;
  }
  function settingsFrom(s) {
    const preset = Object.hasOwn(D.presets,s?.preset) ? s.preset : 'Balanced';
    const max = Number.isInteger(s?.maxChanges) && s.maxChanges >= 0 && s.maxChanges <= 20 ? s.maxChanges : 0;
    return {enabled:s?.enabled !== false,preset,maxChanges:max,categories:s?.categories || {},disabledRules:s?.disabledRules || {}};
  }
  function transformPlain(text, settings, preset, remaining) {
    if (!text || remaining <= 0) return {parts:[{text}],count:0};
    const lower = text.toLowerCase(), parts=[], pusher=(s, extra={})=>{if (s) parts.push({text:s,...extra})};
    let position=0, changes=0, pending='';
    while (position<text.length) {
      const bucket=indexed[lower[position]];
      let selected=null, replacement=null;
      if (bucket && changes<remaining && (position===0 || !isWord(text[position-1]))) {
        for (const rule of bucket) {
          const last=position+rule.length;
          if (lower.slice(position,last)===rule.source && (last===text.length || !isWord(text[last])) &&
              rule.tier<=preset.tier && settings.categories[rule.category]!==false && settings.disabledRules[rule.source]!==true) {
            const candidate = contextReplacement(rule,lower,position,last);
            if (candidate!==null) { selected=rule;replacement=candidate;break; }
          }
        }
      }
      if (selected) {
        pusher(pending);pending='';
        const original=text.slice(position,position+selected.length);
        pusher(matchCase(original,replacement),{changed:true,source:original,rule:selected.source});
        position+=selected.length;
        changes++;
      } else {
        pending+=text[position];position++;
      }
      if (changes>=remaining) {pending+=text.slice(position);break;}
    }
    pusher(pending);
    return {parts,count:changes};
  }
  function transform(text, options={}) {
    if (typeof text !== 'string' || !text || text.startsWith('/')) return {text, count:0, parts:[{text:text||''}]};
    const settings=settingsFrom(options), preset=D.presets[settings.preset];
    if (!settings.enabled) return {text,count:0,parts:[{text}]};
    // All three presets have an unlimited default (limit === 0).
    // An explicit maxChanges 1–20 enables an optional per-message cap.
    // reviewUnlimited is a browser-only override for side-by-side review.
    const limit=options.reviewUnlimited === true || (settings.maxChanges===0 && preset.limit===0)
      ? Number.POSITIVE_INFINITY : (settings.maxChanges>0 ? settings.maxChanges : preset.limit);
    const parts=[];
    let changes=0,cursor=0,position=0;
    const plain = (s)=>{const res=transformPlain(s,settings,preset,limit-changes);parts.push(...res.parts);changes+=res.count;};
    while (position<text.length) {
      const length=protectedLength(text,position);
      if (length) {
        if (position>cursor) plain(text.slice(cursor,position));
        parts.push({text:text.slice(position,position+length),protected:true});
        position+=length;cursor=position;
      } else position++;
    }
    if (cursor<text.length) plain(text.slice(cursor));
    return {text:parts.map(p=>p.text).join(''),count:changes,parts};
  }
  const API={transform,settingsFrom,data:D};
  root.DWARVEN_ENGINE=API;
  if (typeof module!=='undefined' && module.exports) module.exports=API;
})(typeof window!=='undefined' ? window : globalThis);
