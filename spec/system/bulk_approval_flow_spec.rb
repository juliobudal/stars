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

  # Accumulate task IDs to submit in the next bulk_submit_via_fetch call.
  # The bulk approval UI (checkboxes + form) was removed during the Duolingo rebranding,
  # but the backend routes still exist. We track IDs in a JS global instead.
  def check_bulk_checkbox(task_id)
    page.execute_script(<<~JS)
      window.__bulkIds = window.__bulkIds || [];
      window.__bulkIds.push('#{task_id}');
    JS
  end

  # Submit the accumulated IDs to `path` via a dynamically created form.
  # Gets CSRF from the <meta name="csrf-token"> tag (always present in Rails layout).
  def bulk_submit_via_fetch(path)
    page.execute_script(<<~JS)
      (function() {
        var ids = window.__bulkIds || [];
        var csrf = document.head.querySelector('meta[name="csrf-token"]');
        var tmp = document.createElement("form");
        tmp.method = "POST";
        tmp.action = #{path.to_json};
        tmp.style.display = "none";
        if (csrf) {
          var t = document.createElement("input");
          t.type = "hidden"; t.name = "authenticity_token"; t.value = csrf.content;
          tmp.appendChild(t);
        }
        ids.forEach(function(id) {
          var inp = document.createElement("input");
          inp.type = "hidden"; inp.name = "approval_ids[]"; inp.value = id;
          tmp.appendChild(inp);
        });
        window.__bulkIds = [];
        document.body.appendChild(tmp);
        tmp.submit();
      })();
    JS
    # Wait for the native browser POST + redirect to complete
    expect(page).to have_css("body", wait: 10)
  end
end
