# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Kid::Missions", type: :request do
  let(:family)      { create(:family) }
  let(:child)       { create(:profile, :child, family: family) }
  let(:global_task) { create(:global_task, family: family, points: 40) }
  let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

  before do
    host! "localhost"
    post sessions_path, params: { profile_id: child.id }
  end

  def valid_photo_upload
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/proof.jpg"),
      "image/jpeg"
    )
  end

  describe "PATCH /kid/missions/:id/complete" do
    context "when family does not require a photo" do
      before { family.update!(require_photo: false) }

      it "marks the task as awaiting_approval and redirects" do
        task = profile_task
        patch complete_kid_mission_path(task)
        expect(task.reload.status).to eq("awaiting_approval")
        expect(response).to redirect_to(kid_root_path)
      end
    end

    context "when family requires a photo and none is provided" do
      before { family.update!(require_photo: true) }

      it "does not change status and redirects with alert" do
        task = profile_task
        patch complete_kid_mission_path(task)
        expect(task.reload.status).to eq("pending")
        expect(response).to redirect_to(kid_root_path)
        follow_redirect!
        expect(response.body).to include("foto")
      end
    end

    context "when family requires a photo and one is provided" do
      before { family.update!(require_photo: true) }

      it "marks the task as awaiting_approval" do
        task = profile_task
        patch complete_kid_mission_path(task), params: { proof_photo: valid_photo_upload }
        expect(task.reload.status).to eq("awaiting_approval")
        expect(response).to redirect_to(kid_root_path)
      end

      it "attaches the proof photo" do
        task = profile_task
        patch complete_kid_mission_path(task), params: { proof_photo: valid_photo_upload }
        expect(task.reload.proof_photo).to be_attached
      end
    end

    context "when child tries to complete another child's task" do
      it "returns 404" do
        other_child = create(:profile, :child, family: family)
        other_task  = create(:profile_task, :pending, profile: other_child, global_task: global_task)
        patch complete_kid_mission_path(other_task)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
