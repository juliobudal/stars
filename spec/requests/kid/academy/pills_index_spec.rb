# frozen_string_literal: true

require "rails_helper"

# Plan D — "Caderno de pílulas". Lists every PillView the kid has taken,
# newest first, paginated. Empty state nudges back to the daily pill.
RSpec.describe "Kid academy pills index (caderno)", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }
  let(:concept) { create(:academy_concept, slug: "pills-idx-c") }

  def make_pill_view(created_at:, lens_type: "narrative", concept_slug: nil)
    cpt = concept_slug ? create(:academy_concept, slug: concept_slug) : concept
    cache = Academy::LensCache.create!(
      concept: cpt, lens_type: lens_type, age_band: "kid", locale: "pt-BR",
      source: "curated", payload: { stub: true }, quality_flagged: false,
      generated_at: Time.current
    )
    Academy::PillView.create!(
      learner_id: child.id, lens_cache: cache, status: "viewed",
      viewed_at: created_at, created_at: created_at
    )
  end

  before { sign_in_as(child, pin: "1234") }

  it "shows the empty state when the learner has no pill views" do
    get kid_academy_pills_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nenhuma pílula ainda")
    expect(response.body).to include("Tomar a pílula do dia")
  end

  it "lists the learner's pill views newest-first with the concept name visible" do
    make_pill_view(created_at: 3.days.ago)
    make_pill_view(created_at: 1.day.ago, lens_type: "scientific", concept_slug: "pidx-second")

    get kid_academy_pills_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(concept.name)
    expect(response.body).to include("pills-index-list")
  end

  it "paginates past PAGE_SIZE entries" do
    (Kid::Academy::PillsController::PAGE_SIZE + 1).times do |i|
      make_pill_view(
        created_at: (i + 1).hours.ago,
        lens_type: "narrative",
        concept_slug: "pidx-pag-#{i}"
      )
    end

    get kid_academy_pills_path
    expect(response.body).to include("Próxima")

    get kid_academy_pills_path(page: 2)
    expect(response.body).to include("Anterior")
  end
end
