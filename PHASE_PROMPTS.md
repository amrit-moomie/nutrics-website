# Nutrics website content rework — Part B phase prompts

Roadmap reference: `/Users/amrit/.claude/plans/ok-review-users-amrit-workspace-nutrics-transient-frost.md`

Each phase below is a self-contained prompt for a fresh Claude Code chat. Run phases in order (B1 assumes B0 is done, B2 assumes B1, etc.) — don't run multiple B-phases concurrently in separate chats since each depends on the last. The companion clientApp/backend track (Part A) is independent and lives in `nutrics/PHASE_PROMPTS.md`.

To use: open a new Claude Code chat in this repo and paste one phase's prompt block.

---

## Phase B0 — Compliance-flag fixes

```
I'm working on the Nutrics marketing site at /Users/amrit/Workspace/nutrics-website — a static, hand-authored HTML/CSS/vanilla-JS site (no framework, no build system, no CMS; all copy is hardcoded directly in the HTML files).

Context: there's an approved implementation roadmap at
/Users/amrit/.claude/plans/ok-review-users-amrit-workspace-nutrics-transient-frost.md
Read that file first — it covers the full Nutrics Toronto 2026 v2 rework (Part A: clientApp/backend, Part B: nutrics-website). I only want you to implement **Phase B0 — Compliance-flag fixes** from Part B right now. Do not start on later phases (B1+) or Part A.

Also read the three source guides in full before making any changes — they're PDFs at:
- /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Marketing_Guide_Toronto_2026.pdf
- /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Survival_Guide_Toronto_2026.pdf
- /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Product_UX_Vision_Toronto_2026_v2.pdf
(The Survival Guide is the one most relevant to this specific phase — it has a numbered "Mistake" list with compliance gates; Mistake 38 is the one directly triggering this phase.)

Phase B0 scope:
1. **Fix the "Registered Dietitian" title risk**: `partners.html` currently contains the claim "Nutrics nutritionists calculate the macros." In Ontario, "Registered Dietitian" is a legally restricted title (per the Survival Guide's Mistake 38 and the College of Dietitians of Ontario) — "nutritionist" is unregulated/ambiguous and this claim has no credentials or disclaimer attached. Fix it to be accurate and non-misleading — e.g. reframe to something like "Our nutrition team calculates the macros" (don't claim "Registered Dietitian" involvement unless it's actually true — if you're unsure whether Nutrics actually employs a Registered Dietitian, use the safer unregistered framing and flag the ambiguity back to me rather than guessing).
2. Before fixing, `grep -ri "dietitian\|nutritionist" *.html` across the whole site root to confirm this is the only instance (check `index.html`, `partners.html`, `investors.html`, `partner-link-builder.html` too).
3. **Fix dead footer links**: `index.html`'s footer has literal unlinked text "Privacy Policy | Terms of Service" with no actual href or page behind either. Either (a) build minimal `privacy.html` and `terms.html` stub pages and link to them, or (b) remove the dead text if real policy pages aren't ready to be authored yet. Use your judgment on which is better, but a dead-link-looking piece of unlinked text is worse than removing it — don't leave it as-is. If you create stub pages, keep them honest/minimal (e.g. "This page is being finalized — contact hello@nutrics.ca with questions") rather than fabricating legal content.

Also apply the same "grep across the site first, fix everywhere it appears" approach if you spot any other instance of the same dietitian/nutritionist issue while you're in there — but don't go looking for unrelated issues; those are later phases (B1+) and out of scope for this session.

Constraints:
- No CMS/build step — every change is a direct hand-edit to the HTML files. There's no staging/preview pipeline.
- Don't touch `index.html`'s hero, "How Nutrics Works" section, or any pricing/offer content — that's Phase B1/B3, explicitly out of scope here.
- Match the existing site's tone where you touch copy — `partners.html`'s partner FAQ is already written in a calm, honest, hedged voice; use it as your reference for phrasing.

Verification:
- `grep -ri "dietitian\|nutritionist" *.html` shows only accurate, appropriately-hedged usage afterward.
- Footer links click-test correctly (either real pages or removed, no dead unlinked text remaining).
- Quick manual read-through of everything you changed to confirm nothing else broke.

Start by reading the plan file and the Survival Guide PDF, then grep the site, then make the fixes.
```

---

## Phase B1 — "How Nutrics Works" reframe

```
I'm working on the Nutrics marketing site at /Users/amrit/Workspace/nutrics-website — static hand-authored HTML/CSS/vanilla-JS, no framework/build/CMS.

Read the approved roadmap first: /Users/amrit/.claude/plans/ok-review-users-amrit-workspace-nutrics-transient-frost.md
Implement only **Phase B1 — "How Nutrics Works" reframe** from Part B. Confirm Phase B0 (dietitian/nutritionist claim fix, dead footer links) is already done before starting; if not, stop and tell me.

Read the Marketing Guide PDF in full, especially section 6 ("Homepage and paid creative" — the recommended 7-section homepage architecture and its Mechanism/Learning language) and section 9 ("The brand voice" — Use/Avoid table): /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Marketing_Guide_Toronto_2026.pdf
Also read the Survival Guide PDF's Mistakes 1, 2, and 12 (execution/adaptation framing, personalization-isn't-the-moat, don't market unproven "improves adherence" outcomes — market the mechanism instead): /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Survival_Guide_Toronto_2026.pdf

Read `index.html` in full first, specifically the "How Nutrics Works" section (the one walking through Metabolic modelling → Menu structuring → Portion & combination solver → Taste learning, including a "solver trace" widget showing sampled-days/timing numbers) and the hero section's live macro-dashboard widget (calorie/macro numbers, a "96% match" figure).

Scope:
- Rewrite the "How Nutrics Works" section's copy. Keep its four-step shape (it's structurally fine), but strip the macro-solver engineering-showcase language — de-emphasize or remove the "#18,551 / best of 40,000 sampled days / 6ms" solver-trace widget entirely; it currently reads as a technical performance demo, which contradicts the "calm confidence" brand voice and risks implying a precision/optimization claim the Survival Guide says not to make yet. Reframe each of the four steps toward the guide's actual Mechanism/Learning section language: something like "Tell Nutrics what should fit your week" → "We build a plan from meals local culinary partners can actually produce" → "Rate what worked" → "Next week gets smarter." Use the guide's homepage architecture section 3-4 copy as your direct source for phrasing, don't invent new taglines from scratch.
- Soften the hero's live macro-dashboard widget: drop or de-emphasize the "96% match" precision claim specifically (this is the clearest instance of the personalization/unproven-outcome issue flagged in Survival Guide Mistakes 2/12) — you can keep some visual interest in the hero widget (e.g. showing a sample day's meals), just don't lead with a precision-match percentage.
- Do NOT touch the "Why Nutrics" section — the plan explicitly notes its existing anti-diet-culture copy ("Real Toronto food, not diet food," "not 'perfect macro' promises") is already good and just needs the surrounding sections to stop contradicting it, not to be rewritten itself.
- Do NOT add new sections (Trust, Local food, Pricing) — those are Phases B2/B3, out of scope here.
- If touching the hero widget requires touching `assets/data/hero-catalog.js` or its generator `scripts/build-hero-catalog.mjs`, do the minimum necessary — don't restructure that data pipeline, just adjust what's displayed/emphasized.

Verification: after your edits, run `grep -ri` across `index.html` for the Marketing Guide's AVOID-list phrases — "crush your goals," "perfect macros," "AI optimized your body," "hundreds of restaurants" — confirm none appear (they likely don't already, but this is your check that you didn't introduce any). Confirm the hero `<title>` and H1 ("Your nutrition plan. Already cooked.") are unchanged — that headline is already correct per the plan. Manual browser read-through of the reframed section for tone.

Start by reading the plan file, the two guide sections, and the current `index.html` section in full, then implement.
```

---

## Phase B2 — Trust + Local-food sections

```
I'm working on the Nutrics marketing site at /Users/amrit/Workspace/nutrics-website — static hand-authored HTML/CSS/vanilla-JS, no framework/build/CMS.

Read the approved roadmap first: /Users/amrit/.claude/plans/ok-review-users-amrit-workspace-nutrics-transient-frost.md
Implement only **Phase B2 — Add Trust + Local-food sections** from Part B. Confirm Phases B0 and B1 are already done before starting; if not, stop and tell me.

Read the Marketing Guide PDF's section 6 (homepage architecture items 5 "Trust" and 6 "Local food"): /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Marketing_Guide_Toronto_2026.pdf
Read the Survival Guide PDF's Mistakes 17-21 in full — these directly govern the accuracy/hedging of the Trust section's copy:
- Mistake 17 (portion accuracy claims), Mistake 18 (nutrient-content/health claims like "high protein"/"low sodium" have regulated conditions in Canada — CFIA), Mistake 19 (restaurant/takeout vs prepackaged labelling rules differ, changed in 2026 — don't assert compliance you haven't verified), Mistake 20 (an allergy filter is explicitly NOT a safety guarantee — must use "kitchen-specific allergen capability + clear disclosure + no safe match" framing, never imply guaranteed allergen-free safety), Mistake 21 (Ontario requires potentially-hazardous food at ≤4°C or ≥60°C in transit/storage, subject to exceptions — cold-chain copy must be accurate to this, not vibes-only).
/Users/amrit/Workspace/nutrics-website/guides/Nutrics_Survival_Guide_Toronto_2026.pdf

Scope:
- New **Trust** section on `index.html` (positioned per the guide's section 5, after Mechanism/Learning, before Local food): cover kitchen standards, nutrition transparency, and delivery cadence.
  - Cold-chain copy: reference the Ontario ≤4°C/≥60°C requirement accurately and with appropriate hedging (e.g. "we follow Ontario's food-safety temperature requirements for potentially hazardous food" rather than an absolute unqualified safety guarantee).
  - Allergen copy: explicit "kitchen-specific allergen capability + disclosure + no guaranteed safety" framing — e.g. language to the effect of "we show you what a kitchen can accommodate; because meals are prepared in shared commercial kitchens, we can't guarantee a zero-cross-contact environment" — never use the phrase "allergen-free."
  - Do not assert any specific nutrition-labelling regulatory compliance you can't verify from the guide (per Mistake 19) — keep claims general/accurate rather than specific-and-unverified.
- New **Local food** section on `index.html` (guide's section 6): chef/kitchen storytelling. Reuse the three currently-unreferenced images already sitting in `assets/partners/` — `production-meals.jpg`, `production-stack.jpg`, `spanish-quarters.png` (confirm via `grep -r` that they're genuinely unused elsewhere first) — with new descriptive alt text and short story copy about local culinary partners. You can borrow tone/phrasing patterns from `partners.html`'s existing FAQ, which is already written in a calm, honest, hedged voice consistent with what this section needs.
- Do NOT add pricing/offer content (Phase B3) or retention-moment copy (Phase B4) — out of scope here.
- Update the page's in-page anchor nav (if one exists linking to homepage sections) to include the two new sections, matching the existing anchor-link convention.

Verification: confirm the three image paths resolve correctly from `index.html`'s location (they currently live under `assets/partners/`, referenced today only from `partners.html` at the site root — check relative path correctness); confirm alt text is present and descriptive on both new images; do a line-by-line copy review of the Trust section specifically against Mistakes 17-21 before considering this done — this is the phase most likely to create real legal/compliance exposure if rushed.

Start by reading the plan file and the Survival Guide's Mistakes 17-21 in full, then implement.
```

---

## Phase B3 — Pricing / "Founding 150" offer

```
I'm working on the Nutrics marketing site at /Users/amrit/Workspace/nutrics-website — static hand-authored HTML/CSS/vanilla-JS, no framework/build/CMS.

Read the approved roadmap first: /Users/amrit/.claude/plans/ok-review-users-amrit-workspace-nutrics-transient-frost.md
Implement only **Phase B3 — Pricing / "Founding 150" offer** from Part B. Confirm Phases B0-B2 are already done before starting; if not, stop and tell me.

Read the Marketing Guide PDF's section 5 ("The offer: a routine, not a one-off basket" — this is your primary source for this phase's copy) and section 7 (acquisition/CTA language, specifically the "Build my week" CTA recommendation vs. "Browse 150 meals"): /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Marketing_Guide_Toronto_2026.pdf
Read the Survival Guide PDF's Mistakes 25-27 (don't lead marketing with discounts, don't price off competitor comparisons, don't hide real cost behind "free" framing) and Mistake 34 (cancellation must be easy/findable — mention this near the offer, not just buried elsewhere): /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Survival_Guide_Toronto_2026.pdf

Scope:
- Add a new homepage anchor section (e.g. `#pricing` or `#founding-150`) to `index.html`, matching the site's existing single-page anchor-nav convention — do NOT create a separate `pricing.html` page (the plan's explicit recommendation is a section, not a new page, for lower effort and to avoid fragmenting nav; only reconsider a dedicated page later if this section outgrows the format).
- Content, straight from the Marketing Guide section 5:
  - Frame the offer as **"Founding 150 — 4-week consistency pilot"** — a structured four-week experience, explicitly not a promo-code sale.
  - 10-meal week as the hero/default size, with 6-meal and 14-meal variants mentioned as available options (copy-level mention is sufficient — this phase doesn't require a full interactive size-picker widget, just accurate informative copy; if a simple toggle/tab UI is easy to add without a build step, you can include one, but don't over-engineer it).
  - Ask "which meal occasions Nutrics should cover" framing rather than assuming a fixed breakfast/lunch/dinner schedule.
  - Explicit skip/cancel transparency copy directly near the offer (not just in far-away T&Cs) — short and reassuring, e.g. "Skip, pause or cancel any time — no lock-in."
  - Price shown plainly and directly (use a placeholder/TBD price if a real number isn't available to you — flag this back to me rather than inventing a number).
  - Value-beyond-price bullets: plan learning, easy pause/travel, local culinary variety, fewer weekly decisions.
  - **Do not lead with a discount.** A modest founding-customer incentive is acceptable per the guide, but the primary framing must be the full experience's value, not a percentage off.
- Check the current hero CTA copy in `index.html` — if it's not already "Build my week" (or equivalent action-oriented, non-catalogue-browsing language), update it per guide section 7. If it's already aligned, leave it.
- Refresh `sitemap.xml` — it currently only lists the root URL with a stale last-modified date, and is missing `partners.html`/`investors.html` entirely. Update it to reflect current reality now that B0-B3 have collectively changed the site meaningfully.

Verification: `grep -ri` across `index.html` for "free"/"% off"/other discount-lead phrasing to confirm Mistakes 25-27 compliance — the offer section should read as value-first; manual scroll-through of the full page nav to confirm the new section fits the existing flow and anchor links work; validate `sitemap.xml` is well-formed XML after editing.

Start by reading the plan file and the Marketing Guide's section 5 in full, then implement.
```

---

## Phase B4 — Retention-moment copy pass (optional)

```
I'm working on the Nutrics marketing site at /Users/amrit/Workspace/nutrics-website — static hand-authored HTML/CSS/vanilla-JS, no framework/build/CMS.

Read the approved roadmap first: /Users/amrit/.claude/plans/ok-review-users-amrit-workspace-nutrics-transient-frost.md
Implement only **Phase B4 — Retention-moment copy pass** from Part B — this is the last phase of Part B, explicitly marked optional/lower-priority in the plan. Confirm Phases B0-B3 are already done before starting; if not, stop and tell me.

Read the Marketing Guide PDF's section 8 ("Retention is marketing" — the moment/message/desired-action table) and section 9 ("The brand voice" Use/Avoid table): /Users/amrit/Workspace/nutrics-website/guides/Nutrics_Marketing_Guide_Toronto_2026.pdf

Scope:
- Fold 2-3 of the guide's retention moments — specifically "After onboarding," "Before cutoff," and "Skipped week" are the ones the plan calls out — into the "How Nutrics Works"/mechanism section that was reframed in Phase B1, as short illustrative supporting lines (not a new full section — this is light copy-polish layered into existing content).
- Use the guide's brand-voice USE list directly as your source phrasing: "Here is what we changed," "Skip, pause or change the week," "Your week is handled," "Meals that fit your routine," "Local culinary partners, one standard." Do not paraphrase loosely — pull close to the guide's actual language.
- This phase is explicitly lower-priority — keep changes small and additive; don't restructure sections that B1/B2/B3 already finalized.

Verification: this is also the final phase of the entire Part B website track — before considering it done, do one last full-site read-through of everything B0 through B4 touched, checked against both the Marketing Guide's full AVOID list (section 9) and every Survival Guide "Mistake" gate referenced across B0-B3 (Mistakes 1, 2, 4-ish tone consistency, 12, 17-21, 25-27, 34, 38) — this is the closing compliance/tone sweep for the whole website rework.

Start by reading the plan file and the Marketing Guide's sections 8-9, then implement.
```
