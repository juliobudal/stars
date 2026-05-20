# frozen_string_literal: true

require "rails_helper"

# Trail unlock contract: a mission in a trail is locked iff the
# *previous* mission's progress is not completed or mastered. View logic
# lives at app/views/kid/academy/trails/show.html.erb:38. This spec
# pins it so refactors can't silently break the chain.
RSpec.describe "Kid academy trail unlock", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }

  let(:subject_) { create(:academy_subject, slug: "trail-unlock-sub") }
  let(:trail)    { create(:academy_trail, subject: subject_, slug: "tu-trail", position: 1) }

  let(:concept_a) { create(:academy_concept, slug: "tu-a") }
  let(:concept_b) { create(:academy_concept, slug: "tu-b") }
  let(:concept_c) { create(:academy_concept, slug: "tu-c") }

  let!(:mission_1) do
    create(:academy_mission, subject: subject_, trail: trail, concept: concept_a,
           slug: "tu-m1", position_in_trail: 1, order_in_subject: 1)
  end
  let!(:mission_2) do
    create(:academy_mission, subject: subject_, trail: trail, concept: concept_b,
           slug: "tu-m2", position_in_trail: 2, order_in_subject: 2)
  end
  let!(:mission_3) do
    create(:academy_mission, subject: subject_, trail: trail, concept: concept_c,
           slug: "tu-m3", position_in_trail: 3, order_in_subject: 3)
  end

  before { sign_in_as(child, pin: "1234") }

  def show_trail
    get kid_academy_subject_trail_path(subject_, trail)
    response.body
  end

  it "locks every mission past the first when no progress exists" do
    body = show_trail
    expect(body).to include(kid_academy_subject_mission_path(subject_, mission_1))
    # Locked links point to '#' (see trails/show.html.erb:40).
    locked_count = body.scan(/href="#"/).size
    expect(locked_count).to be >= 2
    # The mission paths for #2 and #3 must NOT be rendered as real links.
    expect(body).not_to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_2)}"))
    expect(body).not_to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_3)}"))
  end

  it "unlocks mission #2 once mission #1 progress is completed" do
    Academy::MissionProgress.create!(
      learner_id: child.id, mission: mission_1, status: :completed,
      started_at: 1.hour.ago, completed_at: Time.current
    )

    body = show_trail
    expect(body).to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_2)}"))
    # Mission #3 still locked.
    expect(body).not_to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_3)}"))
  end

  it "unlocks mission #3 once mission #2 is mastered (mastered counts like completed)" do
    Academy::MissionProgress.create!(
      learner_id: child.id, mission: mission_1, status: :completed,
      started_at: 2.hours.ago, completed_at: 1.hour.ago
    )
    Academy::MissionProgress.create!(
      learner_id: child.id, mission: mission_2, status: :mastered,
      started_at: 1.hour.ago, completed_at: 30.minutes.ago
    )

    body = show_trail
    expect(body).to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_2)}"))
    expect(body).to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_3)}"))
  end

  it "keeps mission #2 locked when mission #1 progress is only in_progress" do
    Academy::MissionProgress.create!(
      learner_id: child.id, mission: mission_1, status: :in_progress,
      started_at: 1.hour.ago
    )

    body = show_trail
    expect(body).not_to include(%(href="#{kid_academy_subject_mission_path(subject_, mission_2)}"))
  end
end
