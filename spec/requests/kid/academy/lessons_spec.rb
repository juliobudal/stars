# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Kid::Academy::Lessons", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }
  let(:trail)  { create(:academy_trail) }
  let!(:l1) { create(:academy_lesson, trail: trail, position: 1) }
  let!(:l2) { create(:academy_lesson, trail: trail, position: 2) }

  before { sign_in_as(child, pin: "1234") }

  describe "GET show" do
    it "renders the first lesson" do
      get kid_academy_trail_lesson_path(trail, l1)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(l1.enigma)
    end

    it "blocks a locked lesson and redirects to the trail" do
      get kid_academy_trail_lesson_path(trail, l2)
      expect(response).to redirect_to(kid_academy_trail_path(trail))
    end
  end

  describe "POST complete" do
    it "marks the lesson complete and redirects to the next one" do
      expect {
        post complete_kid_academy_trail_lesson_path(trail, l1), params: { check_choice: 1 }
      }.to change { Academy::LessonProgress.where(learner_id: child.id).count }.by(1)
      expect(response).to redirect_to(kid_academy_trail_lesson_path(trail, l2))
    end

    it "redirects to the trail after the last lesson" do
      create(:academy_lesson_progress, lesson: l1, learner_id: child.id)
      post complete_kid_academy_trail_lesson_path(trail, l2), params: { check_choice: 1 }
      expect(response).to redirect_to(kid_academy_trail_path(trail))
    end
  end
end
