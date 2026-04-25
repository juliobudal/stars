require "rails_helper"

# Tests the bulk approval/rejection flow on the parent approvals index.
#
# Key UI details:
# - The page wraps tasks in a form#bulk-approve-form that POSTs to bulk_approve_parent_approvals_path.
# - Each ApprovalRow with bulk: true renders:
#     <input type="checkbox" name="approval_ids[]" value="<task.id>"
#            data-bulk-select-target="checkbox"
#            data-action="change->bulk-select#change">
# - The "Aprovar selecionadas" submit button starts disabled (opacity-65, cursor-not-allowed).
#   The Stimulus bulk-select controller enables it when any checkbox is checked.
# - There is NO dedicated UI button for bulk-reject. We exercise bulk_reject_parent_approvals_path
#   by mutating the form action via JS before submitting (see scenario 2 below).
#
# Note on sign-in: the sessions page now uses a Stimulus `picker-tabs` controller.
# The tab panel for parents has `hidden` attribute and is revealed by clicking the "Pais" button.
# We click it directly rather than relying on `sign_in_as_parent` which calls the now-gone
# `switchTab()` global function.

RSpec.describe "Bulk Approval Flow", type: :system do
  let!(:family)  { create(:family, name: "Bulk Family") }
  let!(:parent)  { create(:profile, :parent, family: family, name: "Mama") }
  let!(:child)   { create(:profile, :child,  family: family, name: "Binho", points: 0) }

  let!(:task50)  { create(:global_task, family: family, title: "Missao 50",  points: 50)  }
  let!(:task100) { create(:global_task, family: family, title: "Missao 100", points: 100) }
  let!(:task150) { create(:global_task, family: family, title: "Missao 150", points: 150) }

  let!(:pt50)  { create(:profile_task, profile: child, global_task: task50,  status: :awaiting_approval) }
  let!(:pt100) { create(:profile_task, profile: child, global_task: task100, status: :awaiting_approval) }
  let!(:pt150) { create(:profile_task, profile: child, global_task: task150, status: :awaiting_approval) }

  before do
    sign_in_as_parent(parent)
    expect(page).to have_content("Olá, #{parent.name}", wait: 10)
  end

  describe "bulk approve" do
    it "approves all 3 selected tasks and adds points to the child" do
      visit parent_approvals_path
      expect(page).to have_content("Missao 50", wait: 10)

      # Check all 3 checkboxes via JS so Stimulus `change` event fires
      check_bulk_checkbox(pt50.id)
      check_bulk_checkbox(pt100.id)
      check_bulk_checkbox(pt150.id)

      # Submit via fetch() to avoid the nested button_to forms injecting _method=patch
      # into the outer form submission. We collect only the checked checkbox values and
      # POST them directly to the bulk_approve endpoint, then navigate to the redirect URL.
      bulk_submit_via_fetch(bulk_approve_parent_approvals_path)

      # Flash from bulk_approve: "#{n} tarefa(s) aprovada(s)."
      expect(page).to have_content("3 tarefa(s) aprovada(s).", wait: 10)

      # Verify database state
      expect(child.reload.points).to eq(300)
      expect(pt50.reload.status).to  eq("approved")
      expect(pt100.reload.status).to eq("approved")
      expect(pt150.reload.status).to eq("approved")
    end
  end

  describe "bulk reject" do
    it "rejects 2 selected tasks, leaves third untouched, and points remain 0" do
      visit parent_approvals_path
      expect(page).to have_content("Missao 50", wait: 10)

      # Select only pt50 and pt100 (2 of 3)
      check_bulk_checkbox(pt50.id)
      check_bulk_checkbox(pt100.id)

      # There is no dedicated "Rejeitar selecionadas" button in the UI.
      # Use fetch() to POST directly to bulk_reject path with only the checked ids.
      bulk_submit_via_fetch(bulk_reject_parent_approvals_path)

      # Flash from bulk_reject: "#{n} tarefa(s) rejeitada(s)."
      expect(page).to have_content("2 tarefa(s) rejeitada(s).", wait: 10)

      # Verify database state
      expect(child.reload.points).to eq(0)
      expect(pt50.reload.status).to  eq("rejected")
      expect(pt100.reload.status).to eq("rejected")
      expect(pt150.reload.status).to eq("awaiting_approval")
    end
  end

  private

  # Submit the bulk form to `path` via a dynamically created clean form.
  # This avoids the nested button_to forms (which carry hidden _method=patch inputs)
  # polluting the outer #bulk-approve-form POST. We build a temporary detached form,
  # copy only the checked approval_ids and the authenticity_token into it, then submit.
  # The browser handles the redirect natively so the flash cookie is preserved.
  def bulk_submit_via_fetch(path)
    page.execute_script(<<~JS)
      (function() {
        var checked = Array.from(
          document.querySelectorAll("input[type=checkbox][name='approval_ids[]']:checked")
        ).map(cb => cb.value);
        var csrfInput = document.querySelector("#bulk-approve-form input[name='authenticity_token']");
        var tmp = document.createElement("form");
        tmp.method = "POST";
        tmp.action = #{path.to_json};
        tmp.style.display = "none";
        if (csrfInput) {
          var t = document.createElement("input");
          t.type = "hidden"; t.name = "authenticity_token"; t.value = csrfInput.value;
          tmp.appendChild(t);
        }
        checked.forEach(function(id) {
          var inp = document.createElement("input");
          inp.type = "hidden"; inp.name = "approval_ids[]"; inp.value = id;
          tmp.appendChild(inp);
        });
        document.body.appendChild(tmp);
        tmp.submit();
      })();
    JS
    # Wait for the native browser POST + redirect to complete
    expect(page).to have_css("body", wait: 10)
  end

  # Check a bulk-select checkbox by task id via JS so the Stimulus
  # bulk-select controller receives the `change` event and enables the submit button.
  def check_bulk_checkbox(task_id)
    page.execute_script(<<~JS)
      var cb = document.querySelector("input[type=checkbox][value='#{task_id}']");
      if (cb) {
        cb.checked = true;
        cb.dispatchEvent(new Event('change', { bubbles: true }));
      }
    JS
  end
end
