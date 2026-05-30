# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rewards::TemplateLibrary do
  # Guards Parent::RewardsController#add_from_template (create!): every curated
  # template MUST build a valid Reward under the family's first category.
  let(:family) { create(:family) }
  let(:category) { create(:category, family: family) }

  it "every template builds a valid Reward" do
    described_class.all.each do |tpl|
      reward = Reward.new(
        family: family, category: category,
        title: tpl[:title], icon: tpl[:icon], cost: tpl[:cost]
      )
      expect(reward).to be_valid, "template #{tpl[:key].inspect}: #{reward.errors.full_messages.join(', ')}"
    end
  end

  it "find returns nil for unknown/blank keys" do
    expect(described_class.find("nope")).to be_nil
    expect(described_class.find("")).to be_nil
  end
end
