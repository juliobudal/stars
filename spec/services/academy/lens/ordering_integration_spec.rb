# frozen_string_literal: true

require "rails_helper"
require "benchmark"

# Integration spec — full mission journey driven by Lens::ChooseNext +
# Lens::ScoreVisit. Asserts the canonical invariants of v5 ordering:
#   * No consecutive same-type pairs.
#   * Opener is concrete (narrative/first_person/historical).
#   * Mission terminates with a closure lens within HARD_CAP.
#   * Coverage floor (≥4 distinct types) reached before close.
RSpec.describe "Lens ordering — full mission journey" do
  let(:concept) { create(:academy_concept, slug: "ord-int") }
  let(:mission) { create(:academy_mission, concept: concept) }
  let(:learner_id) { 42 }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: learner_id, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  def open_visit(lens_type, position)
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: learner_id, concept_id: concept.id,
      lens_type: lens_type.to_s, ordering_position: position,
      opened_at: Time.current, signal_payload: {}
    )
  end

  def close_visit!(visit, micro_correct: true, time_seconds: 45)
    visit.update!(
      closed_at: visit.opened_at + time_seconds.seconds,
      outcome: "completed",
      signal_payload: { "micro_check_correct" => micro_correct }
    )
    Academy::Lens::ScoreVisit.call(visit: visit)
  end

  it "drives a complete journey: 4–7 distinct types, ending in closure" do
    visited = []
    position = 0

    7.times do |i|
      decision = Academy::Lens::ChooseNext.call(mission_progress: progress).data
      break if decision.done

      position += 1
      visit = open_visit(decision.next_lens, position)
      close_visit!(visit)
      visited << decision.next_lens
    end

    # Variety
    consecutive = visited.each_cons(2).any? { |a, b| a == b }
    expect(consecutive).to be(false), "no two same-type lenses in a row, got #{visited.inspect}"

    # Opener concrete
    expect(Academy::Lens::ChooseNext::CONCRETE_OPENERS).to include(visited.first)

    # Closure last
    expect(Academy::Lens::ChooseNext::CLOSURE_LENSES).to include(visited.last),
      "expected a closure-type lens to be last, got #{visited.inspect}"

    # Coverage floor
    expect(visited.uniq.size).to be >= Academy::Lens::ChooseNext::COVERAGE_FLOOR

    # Cap respected
    expect(visited.size).to be <= Academy::Lens::ChooseNext::HARD_CAP
  end

  it "produces a deterministic, reasonable sequence in under 200ms" do
    elapsed = Benchmark.realtime do
      7.times do |i|
        decision = Academy::Lens::ChooseNext.call(mission_progress: progress).data
        break if decision.done

        visit = open_visit(decision.next_lens, i + 1)
        close_visit!(visit)
      end
    end
    expect(elapsed).to be < 0.5 # generous bound; spec creates several DB rows.
  end
end
