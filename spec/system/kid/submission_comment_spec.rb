require "rails_helper"

RSpec.describe "Kid submission comment flow", type: :system do
  let!(:family) { create(:family, name: "Comment Family", require_photo: false, auto_approve_threshold: nil) }
  let!(:parent) { create(:profile, :parent, family: family, name: "Pai") }
  let!(:kid)    { create(:profile, :child,  family: family, name: "Beto", points: 0) }
  let!(:global_task) do
    create(:global_task, family: family, title: "Escovar dentes", points: 5)
  end
  let!(:profile_task) do
    create(:profile_task,
           profile: kid,
           global_task: global_task,
           status: :pending,
           assigned_date: Date.current)
  end

  it "kid submits a mission with a comment, parent sees it on the approval queue" do
    sign_in_as_child(kid)
    expect(page).to have_content("Escovar dentes", wait: 10)

    # Open the per-task modal (display:none by default) and fill the submission_comment textarea,
    # then submit through the modal's "Terminei!" button. We do this via JS because the modal
    # starts hidden; the existing `open_modal_and_click` helper is extended inline here so we can
    # also set the textarea value before submitting.
    modal_id = "modal_profile_task_#{profile_task.id}"
    page.execute_script(<<~JS)
      var modal = document.getElementById(#{modal_id.to_json});
      modal.style.display = 'flex';
      var textarea = modal.querySelector('textarea[name="submission_comment"]');
      if (textarea) {
        textarea.value = 'fiz antes de dormir';
        textarea.dispatchEvent(new Event('input', { bubbles: true }));
        textarea.dispatchEvent(new Event('change', { bubbles: true }));
      }
      var btns = modal.querySelectorAll('button, input[type=submit]');
      for (var i = 0; i < btns.length; i++) {
        if (btns[i].textContent.trim().indexOf('Terminei!') !== -1) {
          btns[i].click();
          break;
        }
      }
    JS

    expect(page).to have_content("Missão enviada para aprovação", wait: 10)

    # Comment was persisted on the ProfileTask
    expect(profile_task.reload.submission_comment).to eq("fiz antes de dormir")
    expect(profile_task.status).to eq("awaiting_approval")

    # Parent sees the comment on the approval queue
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, Pai", wait: 10)
    visit parent_approvals_path

    expect(page).to have_content("Escovar dentes")
    expect(page).to have_content("fiz antes de dormir")
  end
end
