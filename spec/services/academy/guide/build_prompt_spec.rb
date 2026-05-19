# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Guide::BuildPrompt do
  let(:concept) do
    create(
      :academy_concept,
      name: "Custo da troca (spec)",
      slug: "switch-cost-spec-#{SecureRandom.hex(3)}",
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

  let(:learner) do
    Academy::Learner.new(id: 99, display_name: "Theo", age_band: "kid", timezone: "America/Sao_Paulo")
  end

  let(:progress) do
    create(:academy_mission_progress, learner_id: learner.id, mission: mission, status: :completed)
  end

  def narrative_cache(generated_at: Time.current)
    Academy::LensCache.create!(
      concept_id: concept.id, lens_type: "narrative",
      age_band: "kid", locale: "pt-BR", source: "curated",
      payload: {
        "character" => { "name" => "Tristan", "age" => 16, "trait" => "mágico amador" },
        "scenes" => [
          { "id" => "s1", "text" => "Tristan estudava magia, não para enganar — para entender o truque." },
          { "id" => "s2", "text" => "Dentro do Google ele viu planilhas otimizando tempo de tela." }
        ],
        "ending" => "Ele saiu em 2015 e hoje fala em parlamentos.",
        "micro_check" => { "question" => "?", "options" => %w[a b c], "correct_index" => 0, "rationale" => "..." }
      },
      generated_at: generated_at
    )
  end

  def statistical_cache(generated_at: Time.current)
    Academy::LensCache.create!(
      concept_id: concept.id, lens_type: "statistical",
      age_band: "kid", locale: "pt-BR", source: "curated",
      payload: {
        "predict_prompt" => "Quantos minutos custa cada interrupção, na média?",
        "predict_unit" => "minutos",
        "predict_min" => 1, "predict_max" => 60,
        "reveal_value" => 23,
        "reveal_source" => "Gloria Mark, UC Irvine, 2008",
        "interpretation" => "23 minutos por beep, cada vez."
      },
      generated_at: generated_at
    )
  end

  def visit(lens_type:, position:, cache:, opened_at: Time.current)
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: learner.id, concept_id: concept.id,
      lens_type: lens_type, lens_cache: cache, ordering_position: position,
      opened_at: opened_at, outcome: "completed"
    )
  end

  it "assembles system prompt with persona v2 + concept floor + lens scene anchors + moment block" do
    cache_a = narrative_cache(generated_at: 2.days.ago)
    cache_b = statistical_cache(generated_at: 1.day.ago)
    visit(lens_type: "narrative",   position: 1, cache: cache_a, opened_at: 2.days.ago)
    visit(lens_type: "statistical", position: 2, cache: cache_b, opened_at: 1.day.ago)

    result = described_class.call(learner: learner, mission: mission)

    expect(result).to be_success
    sys = result.data[:system]
    # Persona voice header
    expect(sys).to include("Você é \"O Guia\"")
    # Concept floor
    expect(sys).to include("Custo da troca (spec)")
    expect(sys).to include("Atenção é caríssima")
    expect(sys).to include("Se você é interrompido")
    # Lens scene anchors (richer than v1 headlines)
    expect(sys).to include("# LENTES RECENTES")
    expect(sys).to include("📖 narrative — Personagem: Tristan, 16")
    expect(sys).to include("📈 statistical")
    expect(sys).to include("revelado: 23 minutos")
    # Moment block — locale/tz dependent only on weekday name, just check header
    expect(sys).to include("# MOMENTO")
    expect(sys).to include("fuso America/Sao_Paulo")
  end

  it "drops newest-first lens scenes until under MAX_SYSTEM_TOKENS, preserving floor" do
    service = described_class.new(learner: learner, mission: mission)
    floor   = service.send(:base_floor, concept: concept, mission: mission)
    fat = "📈 statistical — #{"x" * 220}"
    scenes = Array.new(20) { fat.dup }

    result = service.send(:compose, floor: floor, lens_scenes: scenes,
                          state_block: nil, moment_block: "Segunda, 09:00 (manhã, fuso UTC)")
    tokens = (result.length / 4.0).ceil
    expect(tokens).to be <= Academy::Guide::BuildPrompt::MAX_SYSTEM_TOKENS
    expect(result).to include("Atenção é caríssima")
    expect(result).to include("Se você é interrompido")
  end

  it "omits LENTES RECENTES block when learner has not visited any lens" do
    result = described_class.call(learner: learner, mission: mission)
    expect(result.data[:system]).not_to include("# LENTES RECENTES")
  end

  it "includes ESTADO DO APRENDIZ when learner has mastery signal or wrong streak" do
    Academy::LearnerConcept.create!(learner_id: learner.id, concept: concept, level: 2)
    result = described_class.call(learner: learner, mission: mission)
    expect(result.data[:system]).to include("# ESTADO DO APRENDIZ")
    expect(result.data[:system]).to include("avançado")
  end
end
