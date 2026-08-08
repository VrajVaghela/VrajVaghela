#!/usr/bin/env node
/**
 * Verifies every URL in README.md resolves.
 *
 * Exists because two widely-used profile-README services were found dead during
 * this repo's build (github-readme-stats -> 503 DEPLOYMENT_PAUSED,
 * github-profile-trophy -> 402 DEPLOYMENT_DISABLED). Third-party SVG hosts go
 * offline without warning; run this before pushing README changes.
 *
 *   node scripts/check-links.mjs
 *
 * Relative paths (Action-generated assets) are reported separately - they do not
 * exist until their workflow has run at least once.
 */
import { readFileSync } from 'node:fs';

const README = new URL('../README.md', import.meta.url);
const raw = readFileSync(README, 'utf8');

// Strip HTML comments first. Commented-out images (e.g. the metrics panel, which
// stays disabled until METRICS_TOKEN exists) are not rendered by GitHub, so
// reporting them as missing assets is a false positive.
const text = raw.replace(/<!--[\s\S]*?-->/g, '');

const urls = new Set();
const relative = new Set();

for (const m of text.matchAll(/(?:src|srcset|href)="([^"]+)"/g)) {
  const u = m[1];
  if (u.startsWith('http')) urls.add(u);
  else if (u.startsWith('./')) relative.add(u);
}
for (const m of text.matchAll(/\]\((https?:\/\/[^)\s]+)\)/g)) urls.add(m[1]);

const TIMEOUT_MS = 20000;

// Unfilled TODO placeholders - expected to fail until you replace them.
const PLACEHOLDER = /YOUR_LINKEDIN_SLUG|YOUR_X_HANDLE|YOUR_LEETCODE_USERNAME/;

async function probe(url) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    // Some SVG services reject HEAD; GET is the honest test.
    const res = await fetch(url, { signal: ctrl.signal, redirect: 'follow' });
    await res.arrayBuffer();
    return { url, status: res.status, type: res.headers.get('content-type') || '' };
  } catch (e) {
    return { url, status: 0, type: '', error: e.name === 'AbortError' ? 'timeout' : e.message };
  } finally {
    clearTimeout(t);
  }
}

const list = [...urls].sort();
console.log(`Probing ${list.length} absolute URLs from README.md\n`);

const results = [];
const CONCURRENCY = 6;
for (let i = 0; i < list.length; i += CONCURRENCY) {
  results.push(...(await Promise.all(list.slice(i, i + CONCURRENCY).map(probe))));
}

const failures = results.filter((r) => r.status < 200 || r.status >= 400);
const pending = results.filter((r) => r.status === 404 && r.url.includes('/output/'));
const todos = results.filter((r) => PLACEHOLDER.test(r.url));
const realFailures = failures.filter((r) => !pending.includes(r) && !todos.includes(r));

for (const r of results) {
  const ok = r.status >= 200 && r.status < 400;
  const mark = ok ? 'PASS' : todos.includes(r) ? 'TODO' : pending.includes(r) ? 'WAIT' : 'FAIL';
  const detail = r.error ? r.error : `${r.status} ${r.type.split(';')[0]}`;
  console.log(`${mark}  ${detail.padEnd(28)} ${r.url.slice(0, 110)}`);
}

if (relative.size) {
  console.log(`\nCI-generated assets (checked against origin/main):`);
  const RAW = 'https://raw.githubusercontent.com/VrajVaghela/VrajVaghela/main/';
  for (const r of [...relative].sort()) {
    const res = await probe(RAW + r.replace(/^\.\//, ''));
    const ok = res.status >= 200 && res.status < 400;
    if (!ok) realFailures.push(res);
    console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${String(res.status).padEnd(5)} ${r}`);
  }
}

if (pending.length) {
  console.log(`\n${pending.length} snake asset(s) pending first workflow run - expected before push.`);
}
if (todos.length) {
  console.log(`${todos.length} unfilled placeholder(s) - replace the TODO markers in README.md.`);
}

console.log(
  `\n${results.length - failures.length}/${results.length} live` +
    (realFailures.length ? ` | ${realFailures.length} BROKEN` : ' | no broken links'),
);

process.exit(realFailures.length ? 1 : 0);
