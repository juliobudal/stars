# Roadmap: Milestone 2 - UI/UX Duolingo Rebranding 🦉

> Pivot note: Fredoka → **Nunito** (Google Fonts). All other targets met.

## Phase 1: Tokens & Foundations
- [x] **1.1** Configure Google Fonts (Nunito) in Rails layout. — `app/views/shared/_head.html.erb`
- [x] **1.2** Define Duolingo color palette in theme. — `app/assets/stylesheets/tailwind/theme.css`
- [x] **1.3** Implement "Shadow/Depth" utilities in Tailwind 4. — `shadow-btn-*` utilities in `theme.css:380+`

## Phase 2: Base Components (ViewComponents)
- [x] **2.1** Redesign `Ui::Button` with 3D press effect. — `app/components/ui/btn/btn.css`
- [x] **2.2** Redesign `Ui::Card` with thick borders and custom shadows. — `app/components/ui/card/`
- [x] **2.3** Update `Ui::Badge` with Duolingo-style pill design. — `app/components/ui/badge/`

## Phase 3: Kid View Overhaul
- [x] **3.1** Update Kid Layout with persistent bottom navigation. — `app/views/shared/_kid_nav.html.erb`
- [x] **3.2** Update Mission Cards with bouncy hover. — `app/components/ui/mission_card/`
- [x] **3.3** Update Wallet & Store with vibrant cards. — `app/views/kid/wallet/`, `app/views/kid/rewards/index.html.erb`. Pending/rejected panels wired to `ProfileTask` records.

## Phase 4: Parent View Overhaul
- [x] **4.1** Update Parent Layout to follow design language. — `app/views/layouts/parent.html.erb`
- [x] **4.2** Restyle Parent Dashboard stats and lists. — `app/views/parent/dashboard/index.html.erb`

## Phase 5: Animations & Polish
- [x] **5.1** Integrate `canvas-confetti` as a Stimulus controller. — `app/components/ui/confetti/confetti_controller.js`
- [x] **5.2** "Celebration" trigger on Reward Redemption. — `Rewards::RedeemService#broadcast_celebration`
- [x] **5.3** "Success" trigger on Task Approval. — `Tasks::ApproveService#broadcast_celebration`
- [x] **5.4** Audit and fix responsiveness. — Mobile-first kid views verified at 375/768px breakpoints during pixel-perfect refinement.

### Phase 6: Wishlist & Goal Tracking

**Goal:** Give each kid a single pinned reward goal with a visible progress bar so the aspirational rewards (LEGO, Switch, celular, Disney) feel reachable. Kids stay motivated; parents see what each child is saving toward.
**Requirements:**
- Kid can pin one Reward as their wishlist goal from the rewards index page
- Kid dashboard shows a `Ui::WishlistGoal` card with progress (`points / cost`), star delta remaining, and CTA to redeem when 100% reached
- Parent dashboard surfaces each kid's current wishlist goal via `Ui::KidProgressCard` "Meta atual" line (NOTE: corrects original "parent profile show page" — no `parent/profiles#show` route exists; visibility lives on `parent/dashboard#index`)
- Pinning a second reward replaces the first (single goal per kid in this phase)
- Redeeming the pinned reward auto-clears the wishlist (next pick prompts kid)
- All mutations go through `Profiles::SetWishlistService` returning `ApplicationService::Result`
- Single broadcast source: `Profile#after_update_commit :broadcast_wishlist_card` fires on `points` OR `wishlist_reward_id` change (services do not broadcast directly)
**Depends on:** Phase 5
**Plans:** 8/8 plans complete

Plans:
- [x] 06-01-PLAN.md — Migration + Profile model (FK, association, broadcast callback) + spec extension (Wave 0)
- [x] 06-02-PLAN.md — Profiles::SetWishlistService + spec (Wave 1)
- [x] 06-03-PLAN.md — Ui::WishlistGoal::Component + colocated CSS + broadcast partial + spec + DESIGN.md row (Wave 1)
- [x] 06-04-PLAN.md — Kid::WishlistController + routes + request spec (Wave 2)
- [x] 06-05-PLAN.md — Rewards::RedeemService auto-clear inside transaction + spec extension (Wave 2)
- [x] 06-06-PLAN.md — Kid dashboard slot + reward card pin/unpin toggles (Wave 3)
- [x] 06-07-PLAN.md — Parent dashboard "Meta atual" via KidProgressCard + N+1 fix + spec extension (Wave 3)
- [x] 06-08-PLAN.md — End-to-end system spec + full suite verification (Wave 4)

### Phase 7: PWA (Progressive Web App)

**Goal:** Make LittleStars installable on phones/tablets/desktops with offline shell, install prompt, and app-like UX. Currently `app/views/pwa/manifest.json.erb` exists but is orphaned: no route, no `<link rel="manifest">`, no service worker, no installable icons. Chrome/Edge will not show the install banner; iOS adds a generic icon. This phase fixes all of that so kids can launch the app from their home screen.
**Requirements:**
- `/manifest.json` and `/service-worker.js` resolve via Rails 8 PWA controller (`rails/pwa#manifest`, `rails/pwa#service_worker`)
- `<link rel="manifest">` + `<meta name="theme-color">` present on every layout (kid, parent, application)
- Service worker registered on first page load with versioned cache key + `skipWaiting`/`clients.claim` lifecycle
- Offline app-shell strategy: precache critical assets (root HTML, application JS/CSS bundle hashes from Vite manifest), runtime cache-first for `/icon.*` and Vite-fingerprinted assets, network-first with offline fallback for HTML navigations
- Static `/offline.html` rendered when network-first fails (Duolingo-styled, links back when online via `online` event)
- Install prompt UI: `Ui::InstallPrompt::Component` Stimulus controller catches `beforeinstallprompt`, defers it, renders a dismissible Duolingo-style card on kid + parent layouts; tracks dismissal in `localStorage` (key `pwa-install-dismissed-at`, 7-day cooldown)
- iOS hint banner (separate component): detect iOS Safari + non-standalone via `navigator.standalone === false && /iPad|iPhone|iPod/.test(navigator.userAgent)`, render "Toque em ⎙ depois Adicionar à Tela de Início" hint
- Maskable icons: 192px + 512px PNGs with safe zone padding, manifest entries with `"purpose": "maskable"` AND `"any"`
- Manifest expanded: `"lang": "pt-BR"`, `"dir": "ltr"`, `"orientation": "portrait"`, `"categories": ["education","kids","productivity"]`, `"id": "/?source=pwa"`, screenshots optional
- Lighthouse PWA audit ≥ 90 (installable, fast on mobile, configured for splash screen)
- All component CSS follows DESIGN.md tokens (no raw hex, no retired tokens)
**Depends on:** Phase 6
**Plans:** 7/7 plans complete

Plans:
- [x] 07-01-PLAN.md — Rails PWA routes + manifest expansion + head meta + manifest link tag (Wave 0)
- [x] 07-02-PLAN.md — Maskable PNG icons (192/512) + favicon manifest entries (Wave 0)
- [x] 07-03-PLAN.md — Service worker file + cache strategies + offline.html fallback page (Wave 1)
- [x] 07-04-PLAN.md — Service worker registration JS + update-available Stimulus controller (Wave 1)
- [x] 07-05-PLAN.md — Ui::InstallPrompt::Component + Stimulus controller catching beforeinstallprompt (Wave 2)
- [x] 07-06-PLAN.md — Ui::IosInstallHint::Component for iOS Safari non-standalone users (Wave 2)
- [x] 07-07-PLAN.md — System spec + Lighthouse audit + DESIGN.md rows + verification (Wave 3)

---

**Milestone 2 complete.** Next: launch readiness (rspec stabilization, prod secrets, deploy smoke test).
