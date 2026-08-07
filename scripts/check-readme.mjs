#!/usr/bin/env node
/**
 * Validates README.md against GitHub's markdown sanitizer.
 *
 * GitHub strips <script>, <style>, <iframe>, <form> and inline on* handlers from
 * READMEs, and unbalanced tags silently mangle the layout. This catches both
 * before you push.
 *
 *   node scripts/check-readme.mjs
 */
import { readFileSync } from 'node:fs';

const raw = readFileSync(new URL('../README.md', import.meta.url), 'utf8');
const body = raw.replace(/<!--[\s\S]*?-->/g, ''); // comments are not rendered

let failures = 0;
const fail = (m) => { console.log(`FAIL  ${m}`); failures++; };
const pass = (m) => console.log(`PASS  ${m}`);

// --- 1. constructs GitHub removes -----------------------------------------
const stripped = ['script', 'style', 'iframe', 'form', 'input', 'object', 'embed']
  .filter((tag) => new RegExp(`<${tag}[\\s>]`, 'i').test(body));
if (stripped.length) fail(`GitHub strips these tags: ${stripped.join(', ')}`);
else pass('no tags that GitHub would strip');

if (/\son[a-z]+\s*=/i.test(body)) fail('inline event handler (on*=) will be removed');
else pass('no inline event handlers');

if (/\sclass=/.test(body)) fail('class= attributes are stripped; styling will not apply');
else pass('no class attributes');

// --- 2. tag balance --------------------------------------------------------
const PAIRED = ['div', 'table', 'tr', 'td', 'th', 'details', 'summary', 'picture', 'a', 'sub', 'sup', 'i', 'b', 'p'];
for (const tag of PAIRED) {
  const open = (body.match(new RegExp(`<${tag}(?=[\\s>])`, 'g')) || []).length;
  const close = (body.match(new RegExp(`</${tag}>`, 'g')) || []).length;
  if (open === 0 && close === 0) continue;
  if (open !== close) fail(`<${tag}> unbalanced — ${open} open, ${close} close`);
  else pass(`<${tag}> balanced (${open})`);
}

// --- 3. accessibility ------------------------------------------------------
const imgs = body.match(/<img\s[^>]*>/g) || [];
const noAlt = imgs.filter((t) => !/\salt=/.test(t));
if (noAlt.length) fail(`${noAlt.length}/${imgs.length} <img> missing alt`);
else pass(`all ${imgs.length} <img> tags have alt text`);

// --- 4. remaining placeholders --------------------------------------------
const todos = [...new Set(raw.match(/YOUR_[A-Z_]+/g) || [])];
if (todos.length) console.log(`\nTODO  ${todos.length} placeholder(s) to fill: ${todos.join(', ')}`);

console.log(`\n${raw.split('\n').length} lines / ${(raw.length / 1024).toFixed(1)} KB`);
console.log(failures ? `${failures} problem(s) found.` : 'README is valid for GitHub.');
process.exit(failures ? 1 : 0);
