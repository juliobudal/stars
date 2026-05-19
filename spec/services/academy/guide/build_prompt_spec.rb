# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Guide::BuildPrompt do
  let(:concept) do
    create(
      :academy_concept,
      name: "Custo da troca",
      slug: "switch-cost",
      definition: "Cada interrupção paga um pedágio de reconstrução."
    ).tap do |c|
      c.update_column(:the_essence, "Atenção é caríssima e silenciosa. Cada beep cobra em minutos, não em segundos.")
    end
  end

  let(:mission) do
    create(
      :academy_mission,
      concept: concept,
      title: "Quanto custa uma notificação?",
      central_insight: "Se você é interrompido, paga ~23 min em reconstrução de contexto.",
      angle: "Mostrar o pedágio invisível."
    )
  end

  let(:learner) { Academy::Learner.new(id: 99, display_name: "Theo", age_band: "kid") }

  let(:progress) do
    create(:academy_mission_progress, learner_id: learner.id, mission: mission, status: :completed)
  end

  def cache_row(lens_type:, claim:, source: nil, generated_at: Time.current)
    Academy::LensCache.create!(
      concept_id: concept.id,
      lens_type: lens_type,
      age_band: "kid", locale: "pt-BR", mastery_tier: "any",
      template_version: "v5", prompt_digest: SecureRandom.hex(4),
      source: "curated",
      payload: { "central_claim" => claim, "source" => source },
      generated_at: generated_at
    )
  end

  def visit(lens_type:, position:, cache:)
    Academy::LearnerLensVisit.create!(
      mission_progress: progress,
      learner_id: learner.id,
      concept_id: concept.id,
      lens_type: lens_type,
      lens_cache: cache,
      ordering_position: position,
      opened_at: Time.current,
      outcome: "completed"
    )
  end

  it "assembles a system prompt with persona + concept essence + central insight + visited lens summaries" do
    cache_a = cache_row(lens_type: "narrative",   claim: "Gloria Mark mediu 47s.", source: "Gloria Mark, UC Irvine, 2008", generated_at: 2.days.ago)
    cache_b = cache_row(lens_type: "statistical", claim: "5 × 23 = 115 minutos perdidos.", source: "Mark, replicado 2016/2022", generated_at: 1.day.ago)
    visit(lens_type: "narrative",   position: 1, cache: cache_a)
    visit(lens_type: "statistical", position: 2, cache: cache_b)

    result = described_class.call(learner: learner, mission: mission)

    expect(result).to be_success
    sys = result.data[:system]
    expect(sys).to include("Você é \"O Guia\"")
    expect(sys).to include("Custo da troca")
    expect(sys).to include("Atenção é caríssima")
    expect(sys).to include("Se você é interrompido")
    expect(sys).to include("📖 narrative — Gloria Mark mediu 47s.")
    expect(sys).to include("fonte: Gloria Mark, UC Irvine, 2008")
    expect(sys).to include("📈 statistical — 5 × 23 = 115 minutos perdidos.")
  end

  it "drops newest-first lens summaries until under MAX_SYSTEM_TOKENS, preserving floor" do
    bloated = "x" * 600 # ~150 tokens per lens, after 10 lenses ~1500 tokens
    cache_rows = 10.times.map do |i|
      cache_row(
        lens_type: %w[narrative scientific statistical engineering first_person ethical historical analogy_bridge].cycle.to_a[i],
        claim: "Claim #{i} #{bloated}",
        source: "Source #{i}",
        generated_at: i.hours.ago
      )
    end
    cache_rows.each_with_index { |c, i| visit(lens_type: c.lens_type, position: i + 1, cache: c) }

    result = described_class.call(learner: learner, mission: mission)
    sys = result.data[:system]

    tokens = (sys.length / 4.0).ceil
    expect(tokens).to be <= Academy::Guide::BuildPrompt::MAX_SYSTEM_TOKENS
    expect(sys).to include("Atenção é caríssima") # floor preserved
    expect(sys).to include("Se você é interrompido") # central insight preserved
  end

  it "returns no LIÇÕES section when learner has not visited any lens" do
    result = described_class.call(learner: learner, mission: mission)
    expect(result.data[:system]).not_to include("LIÇÕES QUE A CRIANÇA ACABOU DE VER")
  end
end
