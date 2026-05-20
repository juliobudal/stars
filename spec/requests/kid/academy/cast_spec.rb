# frozen_string_literal: true

require "rails_helper"

# Cast gallery (Plan I). Lists the 5 sub-voices and surfaces which ones the
# learner has already encountered via lens visits.
RSpec.describe "Kid academy cast gallery", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }
  let(:concept) { create(:academy_concept, slug: "cast-c") }
  let(:mission) { create(:academy_mission, concept: concept, with_curated_kid_payload: false) }
  let(:progress) do
    Academy::MissionProgress.create!(
      learner_id: child.id, mission: mission, status: :in_progress, started_at: Time.current
    )
  end

  def add_visit(lens_type)
    @visit_position ||= 0
    @visit_position += 1
    Academy::LearnerLensVisit.create!(
      mission_progress: progress, learner_id: child.id, concept_id: concept.id,
      lens_type: lens_type.to_s, ordering_position: @visit_position,
      opened_at: 5.minutes.ago, closed_at: 1.minute.ago, outcome: "completed"
    )
  end

  before { sign_in_as(child, pin: "1234") }

  it "lists every voice in the roster" do
    get kid_academy_cast_path

    expect(response).to have_http_status(:ok)
    Academy::Lens::Voices.all.each do |voice|
      expect(response.body).to include(voice.name)
      expect(response.body).to include(voice.tagline)
    end
  end

  it "marks voices the learner has met" do
    add_visit(:narrative) # naturalist
    add_visit(:historical) # historian

    get kid_academy_cast_path
    body = response.body
    expect(body).to include("✓ encontrada")
    expect(body.scan("✓ encontrada").size).to eq(2)
  end

  it "celebrates the full roster when all 5 voices have been heard" do
    add_visit(:narrative)     # naturalist
    add_visit(:historical)    # historian
    add_visit(:engineering)   # engineer
    add_visit(:analogy_bridge) # translator
    add_visit(:ethical)       # judge

    get kid_academy_cast_path
    expect(response.body).to include("Conheceu todo o elenco!")
  end
end
