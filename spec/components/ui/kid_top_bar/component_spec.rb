require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidTopBar::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:profile) { create(:profile, :child, name: "Lia", points: 12) }

  it "omits the Sair icon button by default" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile))
    end
    expect(page).not_to have_css("button[aria-label='Sair']")
  end

  it "renders the Sair button when show_signout: true" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile, show_signout: true))
    end
    expect(page).to have_css("button[aria-label='Sair']")
    expect(page).to have_css("form[action$='/profile_session']")
  end

  it "renders the Trocar button by default" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile))
    end
    expect(page).to have_css("button[aria-label='Trocar de perfil']")
  end
end
