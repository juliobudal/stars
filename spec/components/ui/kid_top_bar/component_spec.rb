require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::KidTopBar::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:profile) { create(:profile, :child, name: "Lia", points: 12) }

  it "renders the Sair icon button by default" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile))
    end
    expect(page).to have_css("button[aria-label='Sair']")
    expect(page).to have_css("form[action$='/profile_session']")
  end

  it "omits the Sair button when show_signout: false" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile, show_signout: false))
    end
    expect(page).not_to have_css("button[aria-label='Sair']")
  end

  it "still renders the Trocar button alongside Sair" do
    with_request_url("/kid") do
      render_inline(described_class.new(profile: profile))
    end
    expect(page).to have_css("button[aria-label='Trocar de perfil']")
    expect(page).to have_css("button[aria-label='Sair']")
  end
end
