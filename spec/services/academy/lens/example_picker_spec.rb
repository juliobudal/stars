# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::ExamplePicker do
  # ExamplePicker scans the full LensCache table — any leftover row from a
  # prior interrupted run (transactional fixtures don't help if the process
  # died mid-test) would silently match `candidate_relation` and break the
  # "no candidate rows" cases. Truncating inside the test transaction keeps
  # the scrub local: the rollback restores any pre-existing rows untouched.
  # Delete in FK order: signals → visits → cache.
  before(:each) do
    Academy::LensSignal.delete_all
    Academy::LearnerLensVisit.delete_all
    Academy::LensCache.delete_all
  end

  let!(:target) { create(:academy_concept, slug: "target-c", category: "cognitivo") }
  let!(:other_category) { create(:academy_concept, slug: "other-c", category: "saude") }
  let!(:same_category) { create(:academy_concept, slug: "same-c", category: "cognitivo") }

  def lens_row(concept:, lens_type: "scientific", verdict: "PASS", score: 85, flagged: false)
    Academy::LensCache.create!(
      concept: concept,
      lens_type: lens_type,
      age_band: "kid",
      locale: "pt-BR",
      template_version: "scientific.v3",
      mastery_tier: "any",
      prompt_digest: "abc12345",
      generated_at: Time.current,
      payload: { "headline" => "ex headline for #{concept.slug}",
                 "mechanism_steps" => ["step 1", "step 2", "step 3"] },
      judge_verdict: verdict,
      judge_overall_score: score,
      quality_flagged: flagged
    )
  end

  context "with no candidate rows in cache" do
    it "returns nil payload (caller falls back to hardcoded example)" do
      result = described_class.call(concept: target, lens_type: :scientific)
      expect(result.success?).to be true
      expect(result.data[:payload]).to be_nil
    end
  end

  context "with one PASS row from a different-category concept" do
    it "returns that row's payload" do
      row = lens_row(concept: other_category, verdict: "PASS", score: 95)
      result = described_class.call(concept: target, lens_type: :scientific)
      expect(result.success?).to be true
      expect(result.data[:payload]).to eq(row.payload)
      expect(result.data[:source][:lens_cache_id]).to eq(row.id)
    end
  end

  it "excludes the target concept itself" do
    lens_row(concept: target, verdict: "PASS", score: 95)
    result = described_class.call(concept: target, lens_type: :scientific)
    expect(result.data[:payload]).to be_nil
  end

  it "excludes rows below EXAMPLE_FLOOR even if PASS" do
    lens_row(concept: other_category, verdict: "PASS", score: 80) # floor is 85
    result = described_class.call(concept: target, lens_type: :scientific)
    expect(result.data[:payload]).to be_nil
  end

  it "excludes REVISE / FAIL / skipped rows" do
    lens_row(concept: other_category, verdict: "REVISE", score: 95)
    lens_row(concept: same_category, verdict: "FAIL", score: 95)
    result = described_class.call(concept: target, lens_type: :scientific)
    expect(result.data[:payload]).to be_nil
  end

  it "excludes quality_flagged rows" do
    lens_row(concept: other_category, verdict: "PASS", score: 95, flagged: true)
    result = described_class.call(concept: target, lens_type: :scientific)
    expect(result.data[:payload]).to be_nil
  end

  it "falls back to same-category when no cross-category PASS exists" do
    row = lens_row(concept: same_category, verdict: "PASS", score: 95)
    result = described_class.call(concept: target, lens_type: :scientific)
    expect(result.data[:payload]).to eq(row.payload)
  end

  it "prefers cross-category over same-category when both exist" do
    cross = lens_row(concept: other_category, verdict: "PASS", score: 95)
    lens_row(concept: same_category, verdict: "PASS", score: 95)
    # With only one cross-category row, RANDOM() still resolves to it deterministically.
    result = described_class.call(concept: target, lens_type: :scientific)
    expect(result.data[:source][:lens_cache_id]).to eq(cross.id)
  end
end
