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
**Plans:** 8 plans

Plans:
- [x] 06-01-PLAN.md — Migration + Profile model (FK, association, broadcast callback) + spec extension (Wave 0)
- [ ] 06-02-PLAN.md — Profiles::SetWishlistService + spec (Wave 1)
- [ ] 06-03-PLAN.md — Ui::WishlistGoal::Component + colocated CSS + broadcast partial + spec + DESIGN.md row (Wave 1)
- [ ] 06-04-PLAN.md — Kid::WishlistController + routes + request spec (Wave 2)
- [ ] 06-05-PLAN.md — Rewards::RedeemService auto-clear inside transaction + spec extension (Wave 2)
- [ ] 06-06-PLAN.md — Kid dashboard slot + reward card pin/unpin toggles (Wave 3)
- [ ] 06-07-PLAN.md — Parent dashboard "Meta atual" via KidProgressCard + N+1 fix + spec extension (Wave 3)
- [ ] 06-08-PLAN.md — End-to-end system spec + full suite verification (Wave 4)

---

**Milestone 2 complete.** Next: launch readiness (rspec stabilization, prod secrets, deploy smoke test).
