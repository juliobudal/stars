require "rails_helper"

RSpec.describe "Kid completes a repeatable mission", type: :system, js: true do
  let!(:family) { create(:family, require_photo: false, auto_approve_threshold: nil) }
  let!(:parent) { create(:profile, :parent, family: family, name: "Mãe") }
  let!(:kid)    { create(:profile, :child, family: family, name: "Joaninha") }
  let!(:gt) {
    create(:global_task, :daily, family: family, title: "Escovar dentes", points: 5, max_completions_per_period: 3)
  }

  before do
    Tasks::DailyResetService.new(family: family).call
    sign_in_as_child(kid)
    expect(page).to have_content("Escovar dentes", wait: 10)
  end

  it "lets the kid complete the mission three times before the cap blocks it" do
    3.times do |i|
      # Look up the current pending ProfileTask by DB state so we can reference
      # its modal ID. This avoids an ambiguous selector (title text appears in
      # both the mission card and the hidden confirmation modal).
      pt_pending = ProfileTask.where(profile: kid, global_task: gt, status: :pending)
                              .order(:created_at).last
      expect(pt_pending).to be_present, "Expected a pending ProfileTask for iteration #{i}"

      # Open the inline modal via JS (it starts display:none) and click "Terminei!".
      # This mirrors the approach used in kid_flow_spec and full_mission_flow_spec.
      open_modal_and_click("modal_profile_task_#{pt_pending.id}", "Terminei!")

      expect(page).to have_content("Missão enviada para aprovação", wait: 5)

      # Parent approves to free the slot deterministically (no need to drive a
      # second browser session — we approve via the service directly).
      pt = ProfileTask.where(profile: kid, global_task: gt, status: :awaiting_approval)
                      .order(:created_at).last
      Tasks::ApproveService.new(pt).call

      # The new pending row exists in the DB. The kid dashboard does not auto-rebroadcast
      # the new card today (out of scope for this feature), so we re-enter the page to
      # render the fresh state for the next iteration.
      if i < 2
        visit kid_root_path
        expect(page).to have_content("Escovar dentes", wait: 10)
      end
    end

    # All three approvals fired. Refresh once more — cap is now reached, the card
    # must be gone for the rest of the day.
    visit kid_root_path
    expect(page).to have_no_content("Escovar dentes", wait: 10)

    expect(ProfileTask.where(profile: kid, global_task: gt, status: :pending)).to be_empty
    expect(ProfileTask.where(profile: kid, global_task: gt, status: :approved).count).to eq(3)
  end
end
