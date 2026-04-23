---
status: resolved
trigger: kid clicks mission but nothing happens — not marking as pending approval
created: 2026-04-22
updated: 2026-04-22
---

## Symptoms

- expected: clicking mission marks it as pending approval (goes to parent queue)
- actual: nothing happens — no visual feedback, no state change
- errors: no visible error in browser
- reproduction: log in as kid profile, go to dashboard, click any mission

## Current Focus

hypothesis: "data-* attributes for Stimulus not rendered correctly by MissionCard component"
test: "inspect rendered HTML of mission card div"
expecting: "data-action and data-ui-modal-id-param attributes present on div"
next_action: "fix applied"

## Evidence

- timestamp: 2026-04-22
  file: app/components/ui/mission_card/component.html.erb
  note: |
    Both variants (bubble/ticket) serialized @options hash to HTML attributes using
    naive `.map { |k, v| "#{k}=\"#{v}\"" }`. When `data: { action: "...", "ui-modal-id-param": "..." }`
    is passed, the value is a Ruby Hash — rendered as its .to_s ("data=\"{action: ...}\""),
    not as proper data-action="..." data-ui-modal-id-param="..." attributes.
    Result: Stimulus never received the click->ui-modal#open action binding,
    so clicks on mission cards did nothing.

## Eliminated

- route missing (complete_kid_mission_path PATCH /kid/missions/:id/complete exists)
- controller logic (Kid::MissionsController#complete is correct)
- turbo stream response (complete.turbo_stream.erb is correct)

## Resolution

root_cause: "Ui::MissionCard::Component used naive hash-to-string serialization for HTML attributes, causing nested :data hashes to render as Ruby .to_s instead of proper data-* HTML attributes, so Stimulus action bindings were never written to the DOM."
fix: "Added extra_html_attrs helper method to component.rb that expands nested hashes (e.g. data: { action: 'x', 'foo-param': 'y' }) into individual data-action='x' data-foo-param='y' attributes. Updated both variants in component.html.erb to call extra_html_attrs instead of the broken inline map."
verification: "Mission card click should now open confirmation modal, and clicking 'Terminei!' submits PATCH /kid/missions/:id/complete, moving task to awaiting_approval status."
files_changed: "app/components/ui/mission_card/component.rb, app/components/ui/mission_card/component.html.erb"
