# Web app template

Org scaffold for `/init-project` — **not** kawader.

Depends on **`@enjaz/design-system`** (`../../../enjaz/packages/design-system`). Legacy UI files under `resources/js/components/ui/` are duplicated for offline template builds; prefer the package in new apps.

## Stack

- Laravel 13 + Inertia + Vue 3 + Vite
- Tailwind CSS v4
- **@enjaz/design-system** (shadcn-vue primitives + org tokens)
- **Lucide** (`lucide-vue-next`)
- Google OAuth shell (home, login, dashboard)

## Usage

```bash
shared-assets/scripts/init-project/scaffold-web.sh my-app ~/Documents/work/projects/monjizeen closed
```

Third arg controls auth shell behavior: `closed` redirects guests from `/` to `/login`; `open` keeps the public home page. Scaffold installs org Cursor rules (`org-*.mdc`) and seeds `BRIEF.md` from the design-system template.

## Agent: Gate 3 mock data (required)

`/new-project` Gate 3 must **not** leave this shell empty. After copy:

1. Add purpose-shaped models + seeder + dashboard/list UI that shows fake rows
2. Strip kawader leftovers that do not belong
3. Confirm `php artisan migrate:fresh --seed` shows non-empty primary screens

See `shared-assets/skills/new-project/SKILL.md` → Gate 3.

## Agent: new pages

1. `enjaz/packages/design-system/docs/NEW-PAGE.md`
2. https://enjaz.mnjz.in (live gallery)
3. Pattern slugs: `enjaz/packages/design-system/docs/INDEX.md`

## Rebuild (maintainers)

Regenerates this folder from kawader OAuth shell (domain code stripped) + monjizeen UI primitives:

```bash
shared-assets/scripts/init-project/build-web-app-template.sh
```

Commit the result when the template changes.
