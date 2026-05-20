# frozen_string_literal: true

require "rails_helper"

# Lightning Round end-to-end (Plan G).
#
# Covers: the round builder needs ≥5 fading concepts with curated payloads
# whose `micro_check` is present. Less than that → redirect with copy.
# Submitting answers scores correct count, bumps `LearnerConcept.level`
# on hits, and renders the result tier copy.
RSpec.describe "Kid academy Lightning Round", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }

  def seed_fading_concept(slug:, level: 1, idx:)
    concept = create(:academy_concept, slug: slug, name: "Concept #{idx}")
    Academy::LearnerConcept.create!(
      learner_id: child.id, concept: concept, level: level,
      last_seen_at: 10.days.ago
    )
    Academy::LensCache.create!(
      concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
      source: "curated", quality_flagged: false, generated_at: Time.current,
      payload: {
        "character" => { "name" => "Lia", "age" => 9, "trait" => "curiosa e atenciosa" },
        "scenes" => [
          { "id" => "s1", "text" => "Lia tentou uma coisa nova hoje. Foi pequena. Ela não desistiu." },
          { "id" => "s2", "text" => "No dia seguinte, ela tentou de novo. E foi um pouco melhor que ontem." },
          { "id" => "s3", "text" => "Depois de uma semana, ela viu que tinha mudado. Pouco, mas mudado." }
        ],
        "ending" => "Cada vez pequena foi virando uma cadeia. Foi assim que Lia aprendeu a continuar.",
        "micro_check" => {
          "question" => "Qual é a ideia central da história?",
          "options" => [ "Tentar uma vez basta", "Pequenas tentativas viram mudança", "Mudança vem do nada" ],
          "correct_index" => 1,
          "rationale" => "Cada pequena ação se soma — esse é o ponto."
        }
      }
    )
    concept
  end

  before { sign_in_as(child, pin: "1234") }

  context "with not enough fading concepts" do
    it "redirects with a friendly copy" do
      get kid_academy_lightning_path
      expect(response).to redirect_to(kid_root_path)
      follow_redirect!
      expect(response.body).to match(/poucas pílulas|indisponível/i)
    end
  end

  context "with 5+ fading concepts" do
    let!(:concepts) do
      5.times.map { |i| seed_fading_concept(slug: "lr-c-#{i}", idx: i) }
    end

    it "renders the round with 5 questions" do
      get kid_academy_lightning_path
      expect(response).to have_http_status(:ok)
      question_count = response.body.scan(/name="answer\[q\d\]"/).size
      expect(question_count).to be >= 5
    end

    it "scores submitted answers and bumps level on correct picks" do
      get kid_academy_lightning_path
      rounds = session_rounds_for_request

      # All correct.
      payload = rounds.each_with_index.each_with_object({}) do |(r, i), h|
        h["q#{i}"] = r[:correct_index].to_s
      end

      expect {
        post kid_academy_lightning_path, params: { answer: payload }
      }.to change { Academy::LightningRoundRun.for_learner(child.id).count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/perfeit|incrível|mandou bem/i).or match(/\b5\b/)

      bumped = Academy::LearnerConcept.for_learner(child.id).where(level: 2).count
      expect(bumped).to eq(5)

      run = Academy::LightningRoundRun.for_learner(child.id).first
      expect(run.correct_count).to eq(5)
      expect(run.total_questions).to eq(5)
      expect(run.tier).to eq("perfect")
    end
  end

  # Reads the rounds the controller stashed in the session — exposed for the
  # spec via a request env helper since we can't easily inspect session from
  # rack-test directly without a hack.
  def session_rounds_for_request
    # We saved rounds in the session under :lightning_rounds.
    JSON.parse(request.session[:lightning_rounds].to_json, symbolize_names: true) ||
      Array(session[:lightning_rounds])
  end
end
