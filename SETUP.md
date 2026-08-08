# Setup — finishing the profile

The README is the biggest piece, but it only covers part of what makes the profile land.
These steps need your GitHub session, so they're yours to run.

Ordered by impact.

---

## 1. Push this repo

The repo `VrajVaghela/VrajVaghela` is currently **empty**, so this first push creates `main`.

```bash
cd "E:/vraj/Projects/vraj-github-repo"
git add -A
git commit -m "feat: profile dashboard with animated stats and CI-generated assets"
git push -u origin main
```

No credential helper is configured on this machine, so Git will prompt. Use a
**Personal Access Token as the password** (GitHub removed password auth) — or install
[GitHub CLI](https://cli.github.com/) and run `gh auth login` first.

---

## 2. Set your six pins ⭐ *highest impact*

Your profile currently shows **"Popular repositories"**, which is GitHub's automatic
fallback when no pins are set. It's surfacing your 2025 beginner JavaScript work
(`keep`, `UrltoQr`, `Secrets`, `EmployeeManagementSystem`) and hiding everything good.

Go to your profile → **Customize your pins** → select exactly these six:

| Pin | Why |
| :-- | :-- |
| `CrimeOS` | Strongest project. Agentic AI, hackathon-built, 16.7 KB README |
| `ghost_ai` | Deployed and real. 22.2 KB README |
| `FinSight` | Shows the Python/data side. 14.0 KB README |
| `gitassist` | Developer tooling. 8.7 KB README |
| `firewall` | Rust. Differentiates you from every other AI-focused student |
| `autoclassroom` | Memorable, and demonstrates agent work |

Every one of these has a substantial README — that's why they were chosen. Deliberately
**not** pinned: `jobpilot`, `nodebase`, `vocaba`. They're good projects, but their READMEs
404, so pinning them would send visitors to an empty page. Add a README and they become
pin-worthy (see step 6).

---

## 3. Fill in the three placeholders

Search `README.md` for `TODO` — there are three:

| Placeholder | Replace with |
| :-- | :-- |
| `YOUR_LINKEDIN_SLUG` | The part after `linkedin.com/in/` |
| `YOUR_X_HANDLE` | Your X username, no `@` |
| `YOUR_LEETCODE_USERNAME` | Your LeetCode username |

Then confirm nothing is broken:

```bash
node scripts/check-links.mjs
```

If you don't have one of these accounts, delete that whole `<a>...</a>` block rather than
leaving a dead badge.

---

## 4. Set your bio

Your bio, location, company, and website are all currently empty. Go to
**Profile → Edit profile** and set:

**Bio** (under GitHub's 160-char limit):

```
CS student building AI products. Agentic workflows, RAG, and multi-agent systems — mostly TypeScript & Python, occasionally Rust.
```

Also worth filling: **Location**, and **Website** pointing at your best live project.
Tick **"Show Achievements"** while you're there.

---

## 5. Enable the stats card (optional)

The README's large overview panel is rendered by `.github/workflows/metrics.yml` **into
this repo**, rather than fetched from `github-readme-stats.vercel.app` — that service
returned `503 DEPLOYMENT_PAUSED` on every attempt while this was built, and its own docs
warn the public instance is unreliable.

**It is currently commented out in `README.md`**, because without the token it would render
as a broken image. To turn it on:

1. Create a **classic** PAT at [github.com/settings/tokens](https://github.com/settings/tokens)
   with scopes `public_repo` and `read:user`.
2. In this repo: **Settings → Secrets and variables → Actions → New repository secret**
3. Name it exactly `METRICS_TOKEN`, paste the token.
4. **Actions** tab → *Generate Metrics* → **Run workflow**.
5. Once it goes green, delete the two comment markers around the `metrics-overview.svg`
   `<img>` in `README.md` (search for `METRICS_TOKEN` — it's flagged inline).

**Skipping this is fine.** The README already renders four `github-profile-summary-cards`
panels plus the streak card, none of which need a token. You'd only be missing one extra
panel.

---

## 6. Add descriptions and topics to bare repos

13 of your 28 repos have no description, and almost none have topics. Descriptions show up
in search, on your repo list, and on pins — blank ones read as abandoned.

Set a token and run:

```bash
export GH_TOKEN=ghp_your_token_here   # needs 'public_repo' scope
bash scripts/set-repo-metadata.sh
```

Review the descriptions in that script first and edit any you disagree with — they were
inferred from your code, not written by you.

---

## 7. Verify

After pushing, check the **Actions** tab. Three workflows should run:

| Workflow | Needs a secret? | Produces |
| :-- | :-- | :-- |
| `Generate Snake Animation` | No | `snake-dark.svg` / `snake-light.svg` on the `output` branch |
| `Generate 3D Contribution Calendar` | No | `profile-3d-contrib/*.svg` on `main` |
| `Generate Metrics` | `METRICS_TOKEN` | `.github/assets/metrics-*.svg` on `main` |

**The snake, 3D, and metrics images will be broken for the first minute or two** — they
don't exist until their workflow finishes. That's expected, not a bug. Refresh your
profile after the runs go green.

Then open `github.com/VrajVaghela` in **both light and dark mode** to confirm the
`<picture>` theme switching works.

---

## Known issue found while building this

**`ghost_ai`'s root route returns 404.** `https://ghost-ai-rho.vercel.app/` 404s, while
`/sign-in` and `/sign-up` both return 200 — so the app is deployed fine but has no landing
page or root redirect. The README links to `/sign-in` as a workaround.

Worth fixing in that repo: add a redirect from `/` to `/sign-in`, or a proper landing page.
A demo link that 404s costs you more than no demo link.

---

## Maintenance

- All actions are pinned to explicit versions (`Platane/snk@v3.5.0`,
  `yoshi389111/github-profile-3d-contrib@v0.9.3`, `lowlighter/metrics@v3.34`).
- Run `node scripts/check-links.mjs` before pushing README changes. Free SVG services
  disappear without warning — two of the most popular ones were already dead when this was
  built (`github-readme-stats` → 503, `github-profile-trophy` → 402). The script tells you
  before visitors find out.
