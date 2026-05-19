# Deferred items — Phase 07 close-out

Pre-existing failures observed during full-suite run for plan 07-07. None
introduced by Phase 7 code (Phase 7 only touches public/ icons, app/views/pwa,
app/components/ui/install_prompt, app/components/ui/ios_install_hint,
app/javascript/pwa.js, app/views/layouts/{kid,parent}.html.erb head + offline.html
+ DESIGN.md + this plan's spec). Confirmed by inspection: the failing specs do
not reference PWA components or routes.

| Spec | Failure | Owning surface |
|------|---------|----------------|
| spec/system/activity_and_balance_flow_spec.rb:68 | "saldo insuficiente" alert flow | Phase 5 / RedeemService UX |
| spec/system/kid_flow_spec.rb:13 | "submeter uma missão" submission flow | Phase 3 missions |
| spec/system/parent/global_task_repeatable_form_spec.rb:9 | hide cap input toggle | Phase 4 repeatable mission form |
| spec/system/parent/global_task_repeatable_form_spec.rb:30 | persist max_completions_per_period | Phase 4 repeatable mission form |
| spec/system/signup_flow_spec.rb:4 | "Senha (mín. 12 caracteres)" field copy | Phase 0 auth |

These are tracked here for a future stabilization phase; do not block Phase 7
close-out per the scope-boundary rule.
