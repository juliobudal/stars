require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::Toggle::Component, type: :component do
  include ViewComponent::TestHelpers

  it "renders a visual switch when no name is given" do
    render_inline(described_class.new(checked: true))
    expect(page).to have_css("span[role='switch'][aria-checked='true']")
  end

  it "renders form-bound checkbox when name is given" do
    render_inline(described_class.new(checked: false, name: "family[require_photo]"))
    expect(page).to have_css("label[aria-label]")
    expect(page).to have_css("input[type='checkbox'][name='family[require_photo]']")
  end
end
