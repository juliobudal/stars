# frozen_string_literal: true

require "rails_helper"

# Focused unit specs for Academy::Missions::Finalize: hook order,
# rollback on intermediate failure, and idempotency. Complements
# lifecycle_spec.rb's integration coverage.
RSpec.describe Academy::Missions::Finalize do
  let(:concept) { create(:academy_concept, slug: "fz-c", name: "FZ Concept") }
  let(:subject_) { create(:academy_subject) }
  let(:mission)  { create(:academy_mission, subject: subject_, concept: concept) }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: 42, mission: mission, status: :in_progress,
      started_at: 1.hour.ago
    )
  end

  before do
    # Neutral stubs — every chained service returns a successful Result so
    # we can assert order/rollback without re-wiring all the receivers.
    allow(Academy::Cards::MintAfterMission).to receive(:call).and_return(
      Academy::ApplicationService::Result.new(success: true, error: nil, data: nil)
    )
    allow(Academy::Pokedex::Advance).to receive(:call).and_return(
      Academy::ApplicationService::Result.new(success: true, error: nil, data: nil)
    )
    allow(Academy::Signals::Record).to receive(:call).and_return(
      Academy::ApplicationService::Result.new(success: true, error: nil, data: nil)
    )
    allow(Academy::Secrets::EvaluateForLearner).to receive(:call).and_return(
      Academy::ApplicationService::Result.new(success: true, error: nil, data: nil)
    ) if defined?(Academy::Secrets::EvaluateForLearner)
  end

  describe "hook order" do
    it "invokes hooks in the fixed sequence: Cards → Pokedex → Signals → Secrets" do
      call_log = []
      allow(Academy::Cards::MintAfterMission).to receive(:call) { call_log << :cards }
      allow(Academy::Pokedex::Advance).to receive(:call) { call_log << :pokedex }
      allow(Academy::Signals::Record).to receive(:call) { call_log << :signals }
      if defined?(Academy::Secrets::EvaluateForLearner)
        allow(Academy::Secrets::EvaluateForLearner).to receive(:call) { call_log << :secrets }
      end

      described_class.call(progress: progress)

      expected = [ :cards, :pokedex, :signals ]
      expected << :secrets if defined?(Academy::Secrets::EvaluateForLearner)
      expect(call_log).to eq(expected)
    end

    it "skips Pokedex when the mission's concept is unset (defensive)" do
      allow(progress.mission).to receive(:concept).and_return(nil)
      allow(progress).to receive(:mission).and_return(progress.mission)
      expect(Academy::Pokedex::Advance).not_to receive(:call)

      result = described_class.call(progress: progress)
      expect(result.success?).to be true
    end
  end

  describe "transaction rollback" do
    it "rolls back progress.status when Cards::MintAfterMission raises" do
      allow(Academy::Cards::MintAfterMission).to receive(:call).and_raise(StandardError, "mint exploded")

      expect {
        described_class.call(progress: progress)
      }.to raise_error(StandardError, "mint exploded")

      expect(progress.reload.status).to eq("in_progress")
      expect(progress.completed_at).to be_nil
    end

    it "rolls back progress.status when Signals::Record raises" do
      allow(Academy::Signals::Record).to receive(:call).and_raise(StandardError, "signal exploded")

      expect {
        described_class.call(progress: progress)
      }.to raise_error(StandardError, "signal exploded")

      expect(progress.reload.status).to eq("in_progress")
    end

    it "does not invoke later hooks when an earlier one raises" do
      allow(Academy::Cards::MintAfterMission).to receive(:call).and_raise(StandardError, "boom")
      expect(Academy::Pokedex::Advance).not_to receive(:call)
      expect(Academy::Signals::Record).not_to receive(:call)

      expect { described_class.call(progress: progress) }.to raise_error(StandardError)
    end
  end

  describe "idempotency" do
    it "refuses to re-finalize a completed progress" do
      described_class.call(progress: progress)
      expect(progress.reload).to be_completed

      result = described_class.call(progress: progress)
      expect(result.success?).to be false
      expect(result.error).to match(/já finalizada/i)
    end

    it "does not double-invoke hooks on the second call" do
      described_class.call(progress: progress)

      expect(Academy::Cards::MintAfterMission).not_to receive(:call)
      expect(Academy::Pokedex::Advance).not_to receive(:call)
      expect(Academy::Signals::Record).not_to receive(:call)

      described_class.call(progress: progress)
    end
  end
end
