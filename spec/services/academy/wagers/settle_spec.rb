# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Wagers::Settle do
  let(:wager) { create(:academy_practice_wager, guide_bet_count: 10) }

  it "records the actual count + note and stamps reported_at" do
    result = described_class.call(wager: wager, actual_count: 12, note: "fiz no caminho da escola")
    expect(result.success?).to be true
    wager.reload
    expect(wager.learner_actual_count).to eq(12)
    expect(wager.learner_note).to eq("fiz no caminho da escola")
    expect(wager.reported_at).to be_present
  end

  it "rejects negative counts" do
    result = described_class.call(wager: wager, actual_count: -3)
    expect(result.success?).to be false
  end

  it "is single-shot — second settle fails" do
    described_class.call(wager: wager, actual_count: 8)
    result = described_class.call(wager: wager, actual_count: 9)
    expect(result.success?).to be false
    expect(result.error).to match(/já reportada/)
  end

  it "computes delta" do
    described_class.call(wager: wager, actual_count: 7)
    expect(wager.reload.delta).to eq(3) # |10-7|
  end
end
