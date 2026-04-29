require 'rails_helper'
require 'view_component/test_helpers'

RSpec.describe Ui::Modal::Component, type: :component do
  include ViewComponent::TestHelpers

  it 'renders default variant' do
    render_inline(described_class.new(title: 'Hello'))
    expect(page).to have_css('.modal-overlay', visible: false)
  end

  it 'accepts variant: :success and applies success class' do
    render_inline(described_class.new(title: 'Done', variant: :success))
    expect(page).to have_css('[data-modal-variant="success"]', visible: false)
  end

  it 'accepts variant: :confirm-destructive' do
    render_inline(described_class.new(title: 'Delete?', variant: :"confirm-destructive"))
    expect(page).to have_css('[data-modal-variant="confirm-destructive"]', visible: false)
  end

  it 'accepts variant: :celebration and includes confetti layer' do
    render_inline(described_class.new(title: 'Yay!', variant: :celebration))
    expect(page).to have_css('[data-modal-variant="celebration"]', visible: false)
    expect(page).to have_css('[data-fx-event="celebrate"][data-fx-tier="big"]', visible: false)
  end

  it 'celebration variant includes auto-dismiss attr (2500ms)' do
    render_inline(described_class.new(title: 'Yay!', variant: :celebration))
    expect(page).to have_css('[data-fx-dismiss-after="2500"]', visible: false)
  end

  it 'invalid variant falls back to :default' do
    render_inline(described_class.new(title: 'X', variant: :wat))
    expect(page).to have_css('[data-modal-variant="default"]', visible: false)
  end

  describe "WAI-ARIA dialog semantics" do
    it "renders the inner shell with role=dialog and aria-modal=true" do
      render_inline(described_class.new(title: "Hi", id: "m1"))
      expect(page).to have_css('div[role="dialog"][aria-modal="true"]', visible: false)
    end

    it "wires aria-labelledby to the title node" do
      render_inline(described_class.new(title: "Confirm", id: "m2"))
      expect(page).to have_css('div[role="dialog"][aria-labelledby="m2-title"]', visible: false)
      expect(page).to have_css('#m2-title', text: "Confirm", visible: false)
    end

    it "wires aria-describedby to the subtitle node when subtitle is present" do
      render_inline(described_class.new(title: "Confirm", subtitle: "This cannot be undone", id: "m3"))
      expect(page).to have_css('div[role="dialog"][aria-describedby="m3-desc"]', visible: false)
      expect(page).to have_css('#m3-desc', text: "This cannot be undone", visible: false)
    end

    it "omits aria-describedby when no subtitle" do
      render_inline(described_class.new(title: "Plain", id: "m4"))
      expect(page).not_to have_css('[aria-describedby]', visible: false)
    end

    it "auto-generates an id when caller omits it" do
      render_inline(described_class.new(title: "X"))
      expect(page).to have_css('div[role="dialog"][aria-labelledby$="-title"]', visible: false)
    end
  end
end
