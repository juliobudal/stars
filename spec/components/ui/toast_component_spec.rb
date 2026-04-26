require 'rails_helper'
require 'view_component/test_helpers'

RSpec.describe Ui::Toast::Component, type: :component do
  include ViewComponent::TestHelpers

  it 'renders a default toast with the given message' do
    render_inline(described_class.new(message: 'Saved'))
    expect(page).to have_css('[data-fx-event="toast"]', text: 'Saved')
  end

  it 'supports variant: :success' do
    render_inline(described_class.new(message: 'Done!', variant: :success))
    expect(page).to have_css('[data-fx-event="toast"][data-fx-variant="success"]', text: 'Done!')
  end

  it 'supports variant: :error' do
    render_inline(described_class.new(message: 'Oops', variant: :error))
    expect(page).to have_css('[data-fx-event="toast"][data-fx-variant="error"]', text: 'Oops')
  end

  it 'sets auto-dismiss attribute (default 3000ms)' do
    render_inline(described_class.new(message: 'Hi'))
    expect(page).to have_css('[data-fx-dismiss-after="3000"]')
  end

  it 'allows custom dismiss duration' do
    render_inline(described_class.new(message: 'Hi', dismiss_after: 5000))
    expect(page).to have_css('[data-fx-dismiss-after="5000"]')
  end
end
