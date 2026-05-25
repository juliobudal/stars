# frozen_string_literal: true

require "rails_helper"

# Mini-desafio commit (QW4): turns a mission's challenge_prompt into a
# ProfileTask in :awaiting_approval status so the parent can approve via
# the normal flow and the kid earns stars.
RSpec.describe "Kid academy mini-desafio commit", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }

  let(:subject_) { create(:academy_subject, slug: "cc-sub") }
  let(:concept)  { create(:academy_concept, slug: "cc-concept") }
  let!(:mission) do
    create(:academy_mission,
           subject: subject_, concept: concept, slug: "cc-mission",
           title: "Desafio test mission",
           challenge_prompt: "Devolva um brinquedo emprestado hoje",
           challenge_when: "hoje",
           challenge_observable: "como você se sentiu depois")
  end

  before do
    Categories::SeedDefaultsService.call(family)
    sign_in_as(child, pin: "1234")
  end

  describe "POST commit_challenge" do
    it "creates a custom ProfileTask in awaiting_approval status" do
      expect {
        post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      }.to change { child.profile_tasks.count }.by(1)

      task = child.profile_tasks.last
      expect(task.source).to eq("custom")
      expect(task.status).to eq("awaiting_approval")
      expect(task.custom_title).to start_with("Desafio: ")
      expect(task.custom_title).to include(mission.title)
      expect(task.custom_description).to eq(mission.challenge_prompt)
      expect(task.custom_points).to eq(5)
      expect(task.custom_category).to be_present
    end

    it "redirects back to the mission page with a notice" do
      post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      expect(response).to redirect_to(kid_academy_subject_mission_path(subject_, mission))
      follow_redirect!
      expect(flash[:notice] || response.body).to include("aprovação")
    end

    it "is idempotent — a second commit does not create a duplicate task" do
      post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      expect {
        post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      }.not_to change { child.profile_tasks.count }
    end

    it "refuses to commit when the mission has no challenge_prompt" do
      mission.update!(challenge_prompt: nil)
      expect {
        post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      }.not_to change { child.profile_tasks.count }
      follow_redirect!
      expect(response.body).to include("mini-desafio")
    end

    it "creates a new task again once the previous one was rejected" do
      post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      child.profile_tasks.last.update!(status: :rejected)

      expect {
        post commit_challenge_kid_academy_subject_mission_path(subject_, mission)
      }.to change { child.profile_tasks.count }.by(1)
    end
  end
end
