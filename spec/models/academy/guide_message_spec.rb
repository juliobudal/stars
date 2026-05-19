# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::GuideMessage do
  it "requires content" do
    expect(described_class.new).not_to be_valid
  end

  it "exposes roles user / guide / system_note" do
    expect(described_class.roles.keys).to match_array(%w[user guide system_note])
  end

  it "defaults flagged false" do
    expect(create(:academy_guide_message).flagged).to be(false)
  end

  it "increments conversation message_count after create" do
    convo = create(:academy_guide_conversation)
    expect { create(:academy_guide_message, conversation: convo) }
      .to change { convo.reload.message_count }.by(1)
  end
end
