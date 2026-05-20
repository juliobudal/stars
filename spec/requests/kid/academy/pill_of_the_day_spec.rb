# frozen_string_literal: true

require "rails_helper"

# Pílula do Dia end-to-end (Plan D). Covers the show contract:
# pick → render → share → idempotent re-pick on the same day.
RSpec.describe "Kid academy Pill of the Day", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }
  let!(:concept) do
    create(:academy_concept, slug: "pdotd-c", name: "Pílula concept",
           active: true, category: "mundo_natural")
  end
  let!(:lens_cache) do
    Academy::LensCache.create!(
      concept: concept, lens_type: "narrative", age_band: "kid", locale: "pt-BR",
      source: "curated", quality_flagged: false, generated_at: Time.current,
      payload: {
        "character" => { "name" => "Lia", "age" => 9, "trait" => "curiosa e atenciosa" },
        "scenes" => [
          { "id" => "s1", "text" => "Lia abriu a janela e olhou o quintal. Tudo parecia o mesmo. Mas o vento mudou de jeito e ela percebeu." },
          { "id" => "s2", "text" => "Ela contou pra avó. A avó sorriu e disse que era só uma frente fria chegando. Mas pediu pra ver junto." },
          { "id" => "s3", "text" => "As duas ficaram um tempo no quintal. Folha mexendo, cachorro inquieto, ar mais leve. Pequenos sinais avisando." }
        ],
        "ending" => "Lia aprendeu que o quintal contava histórias se ela parasse pra escutar. O vento sempre teve coisas a dizer.",
        "micro_check" => {
          "question" => "Qual ideia melhor descreve o que aconteceu?",
          "options" => [ "O vento mudou e nada mais", "Pequenos sinais formam um aviso", "A avó era mágica" ],
          "correct_index" => 1,
          "rationale" => "Vários pequenos sinais juntos formam um padrão — esse é o ponto."
        }
      }
    )
  end

  before { sign_in_as(child, pin: "1234") }

  it "renders the daily pill and creates a PillView" do
    expect {
      get kid_academy_pill_path
    }.to change { Academy::PillView.for_learner(child.id).count }.by(1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Pílula do Dia")
    expect(response.body).to include(concept.name)
  end

  it "is idempotent intra-day (same PillView on second hit)" do
    get kid_academy_pill_path
    pill_view = Academy::PillView.for_learner(child.id).first
    expect(pill_view).to be_present

    expect {
      get kid_academy_pill_path
    }.not_to change { Academy::PillView.for_learner(child.id).count }
  end

  it "redirects to root with a notice when no pill is available" do
    Academy::LensCache.delete_all

    get kid_academy_pill_path
    expect(response).to redirect_to(kid_root_path)
    follow_redirect!
    expect(response.body).to include("Sem pílula nova")
  end

  it "marks pill as shared when the share endpoint is hit" do
    get kid_academy_pill_path
    pill_view = Academy::PillView.for_learner(child.id).first

    expect {
      post kid_academy_share_pill_path(pill_view)
    }.to change { pill_view.reload.shared_with_parent? }.from(false).to(true)
    expect(response).to redirect_to(kid_root_path)
  end
end
