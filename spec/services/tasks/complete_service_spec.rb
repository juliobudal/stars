# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tasks::CompleteService do
  let(:family)      { create(:family) }
  let(:child)       { create(:profile, :child, family: family) }
  let(:global_task) { create(:global_task, family: family, points: 30) }
  let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

  def valid_photo
    Rack::Test::UploadedFile.new(
      Rails.root.join("spec/fixtures/files/proof.jpg"),
      "image/jpeg"
    )
  end

  describe "#call" do
    context "when family does not require a photo" do
      before { family.update!(require_photo: false) }

      it "sets status to awaiting_approval" do
        described_class.new(profile_task: profile_task).call
        expect(profile_task.reload.status).to eq("awaiting_approval")
      end

      it "returns success" do
        result = described_class.new(profile_task: profile_task).call
        expect(result.success?).to be true
        expect(result.error).to be_nil
      end

      it "does not require a photo" do
        result = described_class.new(profile_task: profile_task, proof_photo: nil).call
        expect(result.success?).to be true
      end
    end

    context "when family requires a photo and no photo is provided" do
      before { family.update!(require_photo: true) }

      it "returns failure" do
        result = described_class.new(profile_task: profile_task, proof_photo: nil).call
        expect(result.success?).to be false
        expect(result.error).to be_present
      end

      it "does not change the task status" do
        described_class.new(profile_task: profile_task, proof_photo: nil).call
        expect(profile_task.reload.status).to eq("pending")
      end
    end

    context "when family requires a photo and a valid photo is provided" do
      before { family.update!(require_photo: true) }

      it "sets status to awaiting_approval" do
        described_class.new(profile_task: profile_task, proof_photo: valid_photo).call
        expect(profile_task.reload.status).to eq("awaiting_approval")
      end

      it "attaches the proof photo" do
        described_class.new(profile_task: profile_task, proof_photo: valid_photo).call
        expect(profile_task.reload.proof_photo).to be_attached
      end

      it "returns success" do
        result = described_class.new(profile_task: profile_task, proof_photo: valid_photo).call
        expect(result.success?).to be true
      end
    end

    context "when the task is not pending" do
      let(:profile_task) { create(:profile_task, :awaiting_approval, profile: child, global_task: global_task) }

      it "returns failure" do
        result = described_class.new(profile_task: profile_task).call
        expect(result.success?).to be false
        expect(result.error).to be_present
      end
    end
  end
end
