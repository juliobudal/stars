# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::RecallReminderJob, type: :job do
  let(:card_for) do
    ->(learner_id) {
      Academy::DiscoveryCard.create!(
        learner_id: learner_id,
        mission: create(:academy_mission),
        headline: "h",
        minted_at: 1.week.ago
      )
    }
  end

  it "groups due recall reviews by learner and logs each" do
    review_due = Academy::RecallReview.create!(
      card: card_for.call(1), learner_id: 1,
      streak: 0, interval_days: 1, due_at: 1.hour.ago
    )
    review_future = Academy::RecallReview.create!(
      card: card_for.call(2), learner_id: 2,
      streak: 0, interval_days: 7, due_at: 7.days.from_now
    )
    review_due_2 = Academy::RecallReview.create!(
      card: card_for.call(3), learner_id: 3,
      streak: 0, interval_days: 2, due_at: 1.day.ago
    )

    expect(Rails.logger).to receive(:info).twice

    result = described_class.new.perform

    expect(result.keys).to contain_exactly(1, 3)
    expect(result.values.sum).to eq(2)
    expect(review_future).to be_persisted
  end

  it "returns an empty hash when nothing is due" do
    Academy::RecallReview.create!(
      card: card_for.call(1), learner_id: 1,
      streak: 0, interval_days: 7, due_at: 3.days.from_now
    )

    expect(described_class.new.perform).to eq({})
  end
end
