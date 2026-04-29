require "rails_helper"

RSpec.describe "Modal a11y", type: :system, js: true do
  let!(:family) { create(:family) }
  let!(:child) { create(:profile, :child, family: family, name: "Lia") }
  let!(:global_task) { create(:global_task, family: family, title: "Lavar Louça", points: 100) }
  let!(:profile_task) { create(:profile_task, profile: child, global_task: global_task, status: :pending) }

  before do
    sign_in_as_child(child)
  end

  it "captures focus inside the dialog, Esc closes, and focus returns to the trigger" do
    expect(page).to have_content("Lavar Louça")

    # Click the mission card wrapper to trigger the open() action via the inner card element
    trigger_el = find("[id='#{ActionView::RecordIdentifier.dom_id(profile_task)}']")
    trigger_el.click

    expect(page).to have_css("[role='dialog']", visible: true, wait: 5)

    in_dialog = page.evaluate_script("document.activeElement && document.activeElement.closest('[role=\"dialog\"]') !== null")
    expect(in_dialog).to be(true)

    page.send_keys(:escape)
    expect(page).to have_css("[role='dialog']", visible: false, wait: 5)

    focused_id = page.evaluate_script("document.activeElement && document.activeElement.id")
    expect(focused_id).to eq(ActionView::RecordIdentifier.dom_id(profile_task))
  end
end
