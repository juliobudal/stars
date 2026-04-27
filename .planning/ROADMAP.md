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

---

**Milestone 2 complete.** Next: launch readiness (rspec stabilization, prod secrets, deploy smoke test).
