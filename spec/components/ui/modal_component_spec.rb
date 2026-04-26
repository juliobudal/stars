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
end
