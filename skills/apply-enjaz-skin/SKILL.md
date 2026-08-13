---
name: apply-enjaz-skin
description: >
  Apply a presented app design (HTML/CSS, mocks, redesign) as a theme skin on Enjaz.
  Always install @enjaz/design-system first, analyze tokens/components, then paint via
  CSS variables + Tailwind — never invent a parallel UI kit. Use when Omar says present
  design, apply design, redesign, new skin/theme, or drops HTML/CSS look for a Vue app.
---

# Apply Enjaz skin

Org skill for monjizeen-domain **Laravel + Inertia + Vue** apps.

**Contract:** `enjaz/packages/design-system/docs/THEMES.md`  
**Steps detail:** `enjaz/packages/design-system/docs/APPLY-SKIN.md`  
**Gallery:** https://enjaz.mnjz.in

## When to use

- Omar presents a new look (HTML/CSS files, static gallery, Figma notes, “redesign X”)
- “Apply this design to Monjizeen / Waqti / …”
- “Make this a theme/skin”

## Do not use

- Pure backend / API work
- Adding one missing shadcn primitive with no new product look (use Enjaz agent only)
- Employer / `tier: job` domains

## Pipeline (mandatory order)

### Phase 0 — Scope

1. Confirm **target app repo** (ask if unclear).
2. Confirm design source paths (HTML/CSS/mocks).
3. Log request in `mora/REQUESTS.md` if actionable.

### Phase 1 — Install Enjaz

In the **target app**:

1. Add dependency if missing:
   - Mono: `"@enjaz/design-system": "file:../enjaz/packages/design-system"`
   - Or GitHub dep per Enjaz README
2. `npm install`
3. Vite alias → package `src` (see Enjaz README)
4. CSS: `@import '@enjaz/design-system/styles';` **before** app skin; Tailwind `@source` includes package
5. Install AI rules:
   ```bash
   bash ../enjaz/packages/design-system/scripts/install-cursor-rules.sh "$(pwd)"
   ```
6. Prove import works (dev build or smoke page). **Do not paint until this passes.**

### Phase 2 — Analyze design

From the presented HTML/CSS:

| Extract | Map to |
|---------|--------|
| Brand colors | `--brand-green`, `--brand-navy`, `--brand-blue` + semantic `--primary`, `--background`, … |
| Fonts | `--font-heading*`, `--font-body*` |
| Radius / border / ring | `--radius`, `--border`, `--ring` |
| Light + dark | `:root` and `.dark` |
| UI pieces | Existing `@enjaz/design-system/ui/*` + patterns |
| Missing pieces | List → implement in **enjaz** first |

Output a short **skin brief** (tokens table + component map + gaps). Show Omar TLDR before big page ports if look is ambiguous.

### Phase 3 — Apply skin

1. Create/update app skin file (e.g. `resources/css/app-theme-skin.css`) implementing the Enjaz token contract.
2. Import skin **after** Enjaz styles in `app.css`.
3. Wire fonts (link or `@font-face`) per design.
4. Port screens using **Enjaz components only** + Tailwind for layout/spacing/state.
5. Gaps: add primitive/pattern + gallery demo in `enjaz`, then import in app.
6. Do **not** keep a second Button/Input system in the app.

### Phase 4 — Verify

- Light + dark
- RTL if app is bilingual
- One real page matches the mock intent (not pixel-perfect HTML dump)
- Checks green → commit (push only on ship)

## Success criteria

- [ ] App depends on `@enjaz/design-system`
- [ ] Skin is CSS variables on Enjaz, not a new component library
- [ ] Pages import from `@enjaz/design-system/...`
- [ ] Gaps landed in Enjaz (if any)
- [ ] Omar can see look in the running app

## Related

- Rule: `mora/cursor-runtime/rules/enjaz-design-skin.mdc`
- Enjaz agent: package/gallery ownership
- App agent: page wiring in product repo
