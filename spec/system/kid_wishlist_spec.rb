require "rails_helper"

# End-to-end Capybara coverage for the wishlist mechanic introduced in Phase 06.
#
# Covers the goal-backward derivation chain from CONTEXT.md:
#   kid pins reward → dashboard goal card renders →
#   kid removes the pin → dashboard returns to empty CTA →
#   kid redeems the pinned reward → wishlist auto-clears (DB-level) →
#   parent dashboard surfaces the kid's pinned goal as "Meta: <title>".
#
# The "live update via Turbo Stream from parent task approval" scenario is intentionally
# OMITTED here — the unit-level assertion is already covered by Plan 06-01 (Profile spec
# broadcast tests) and Plan 06-02 (service spec). System spec covers the full HTTP
# round-trip via fresh `visit` calls on each scenario.
RSpec.describe "Kid Wishlist Flow", type: :system do
  let!(:family) { create(:family, name: "Família Teste") }
  let!(:parent_profile) { create(:profile, :parent, family: family, name: "Papai") }
  let!(:child) { create(:profile, :child, family: family, name: "Filhote", points: 50) }
  let!(:reward) { create(:reward, family: family, title: "LEGO Star Wars", cost: 100) }

  # Pin/unpin form submits via Turbo and the controller responds with `head :ok`,
  # so there is no visible DOM change on /kid/rewards to anchor a Capybara matcher
  # to. Poll the DB instead — bounded by Capybara.default_max_wait_time.
  def wait_for(timeout: Capybara.default_max_wait_time, interval: 0.1)
    deadline = Time.now + timeout
    until yield
      raise "Timed out after #{timeout}s waiting for condition" if Time.now > deadline
      sleep interval
    end
  end

  it "permite ao filho fixar um prêmio como meta e o vê no dashboard" do
    sign_in_as_child(child)
    visit kid_rewards_path

    expect(page).to have_content("LEGO Star Wars")

    within("##{ActionView::RecordIdentifier.dom_id(reward)}") do
      # Pin button visible text is "Meta"; the action verb "Definir como meta"
      # lives in the aria-label (Capybara doesn't match aria-label by default).
      find("button[aria-label='Definir como meta']").click
    end

    # The pin form submits via Turbo (head :ok response). The /kid/rewards page
    # has no wishlist Turbo Frame so there's no visible DOM change to await.
    # Poll the DB until the broadcast/commit is observable before navigating.
    wait_for { child.reload.wishlist_reward_id == reward.id }

    visit kid_root_path

    # The "Minha meta" label is `text-transform: uppercase` via CSS, so Selenium
    # reports the visible text as "MINHA META". Use a case-insensitive regex
    # to stay decoupled from the styling.
    expect(page).to have_content(/minha meta/i)
    expect(page).to have_content("LEGO Star Wars")
    expect(page).to have_content("50/100")
    expect(page).to have_content("Faltam")
    expect(child.reload.wishlist_reward_id).to eq(reward.id)
  end

  it "permite ao filho remover a meta fixada" do
    child.update!(wishlist_reward: reward)
    sign_in_as_child(child)
    visit kid_rewards_path

    within("##{ActionView::RecordIdentifier.dom_id(reward)}") do
      find("button[aria-label='Remover meta']").click
    end

    wait_for { child.reload.wishlist_reward_id.nil? }

    visit kid_root_path

    expect(page).to have_content("Escolher um prêmio")
    expect(page).not_to have_content(/minha meta/i)
    expect(child.reload.wishlist_reward_id).to be_nil
  end

  it "limpa a meta automaticamente quando o filho resgata o prêmio fixado" do
    child.update!(points: 100, wishlist_reward: reward)
    sign_in_as_child(child)
    visit kid_rewards_path

    # The redeem flow opens an inline modal (display:none until JS reveal).
    # Mirror the existing analog (spec/system/reward_redemption_flow_spec.rb)
    # using the SystemAuthHelpers#open_modal_and_click helper.
    open_modal_and_click("modal_#{ActionView::RecordIdentifier.dom_id(reward)}", "Sim, quero!")

    expect(page).to have_content("Resgate solicitado!")

    # Auto-clear is a DB-level invariant guaranteed by Rewards::RedeemService
    # (Plan 06-05) regardless of UI state.
    expect(child.reload.wishlist_reward_id).to be_nil
  end

  it "mostra a meta fixada do filho no dashboard do pai" do
    child.update!(wishlist_reward: reward)
    sign_in_as_parent(parent_profile)
    visit parent_root_path

    expect(page).to have_content("Meta:")
    expect(page).to have_content("LEGO Star Wars")
  end
end
