require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::IconPicker::Component, type: :component do
  include ViewComponent::TestHelpers

  let(:default_args) do
    { field_name: "global_task[icon]", value: "bed-single-01", context: :mission, color: "var(--c-blue)", id: "icon_picker_demo" }
  end

  it "renders a hidden input with the given name and value" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("input[type='hidden'][name='global_task[icon]'][value='bed-single-01']", visible: :hidden)
  end

  it "renders a preview button wired to the picker controller" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("button[data-action*='icon-picker#open']")
    expect(page).to have_css("[data-icon-picker-target='previewIcon']")
  end

  it "renders a modal with the given id" do
    render_inline(described_class.new(**default_args))
    expect(page.native.to_html).to include('id="icon_picker_demo_modal"')
  end

  it "exposes the context to the controller via a data attribute" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("[data-icon-picker-context-value='mission']")
  end

  it "renders a search input and the two tab buttons" do
    render_inline(described_class.new(**default_args))
    expect(page).to have_css("[data-icon-picker-target='searchInput']")
    expect(page).to have_css("[data-icon-picker-target='tabCurated']", text: /Sugeridos/i)
    expect(page).to have_css("[data-icon-picker-target='tabCatalog']", text: /Todos/i)
  end

  it "renders Confirmar and Cancelar action buttons" do
    render_inline(described_class.new(**default_args))
    html = page.native.to_html
    expect(html).to match(/Confirmar/)
    expect(html).to match(/Cancelar/)
  end
end
