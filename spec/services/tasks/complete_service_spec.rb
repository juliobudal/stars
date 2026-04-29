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

    context "auto-approval via auto_approve_threshold" do
      let(:global_task) { create(:global_task, family: family, points: 5) }
      let(:profile_task) { create(:profile_task, :pending, profile: child, global_task: global_task) }

      context "when threshold is set, points <= threshold, and require_photo is false" do
        before { family.update!(auto_approve_threshold: 10, require_photo: false) }

        it "auto-approves: status ends up :approved" do
          described_class.new(profile_task: profile_task).call
          expect(profile_task.reload.status).to eq("approved")
        end

        it "credits points to the profile" do
          expect { described_class.new(profile_task: profile_task).call }
            .to change { child.reload.points }.by(5)
        end
      end

      context "when threshold is set but points exceed threshold" do
        let(:global_task) { create(:global_task, family: family, points: 15) }

        before { family.update!(auto_approve_threshold: 10, require_photo: false) }

        it "leaves status as :awaiting_approval" do
          described_class.new(profile_task: profile_task).call
          expect(profile_task.reload.status).to eq("awaiting_approval")
        end

        it "does not credit points" do
          expect { described_class.new(profile_task: profile_task).call }
            .not_to change { child.reload.points }
        end
      end

      context "when threshold is set but require_photo is true and a photo is provided" do
        before { family.update!(auto_approve_threshold: 10, require_photo: true) }

        it "leaves status as :awaiting_approval (photo blocks auto-approve)" do
          described_class.new(profile_task: profile_task, proof_photo: valid_photo).call
          expect(profile_task.reload.status).to eq("awaiting_approval")
        end

        it "does not credit points" do
          expect { described_class.new(profile_task: profile_task, proof_photo: valid_photo).call }
            .not_to change { child.reload.points }
        end
      end

      context "when auto_approve_threshold is nil (feature disabled)" do
        before { family.update!(auto_approve_threshold: nil, require_photo: false) }

        it "leaves status as :awaiting_approval" do
          described_class.new(profile_task: profile_task).call
          expect(profile_task.reload.status).to eq("awaiting_approval")
        end

        it "does not credit points" do
          expect { described_class.new(profile_task: profile_task).call }
            .not_to change { child.reload.points }
        end
      end
    end
  end

  describe "with a repeatable mission (max=3)" do
    let(:family) { create(:family) }
    let(:profile) { create(:profile, :child, family: family) }
    let(:gt) { create(:global_task, :daily, family: family, max_completions_per_period: 3) }
    let(:pt) { create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :pending) }

    before { pt } # materialize so the pending row exists before the change block evaluates

    it "spawns a new pending row after the current one moves to awaiting_approval" do
      # the original row flips to awaiting_approval, a new pending row is created — net unchanged at 1
      described_class.new(profile_task: pt).call
      expect(pt.reload.status).to eq("awaiting_approval")
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending).count).to eq(1)
    end

    it "does not spawn a new pending row once the cap is reached" do
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      create(:profile_task, profile: profile, global_task: gt, assigned_date: Date.current, status: :approved)
      # 2 approved + 1 about-to-be-awaiting = 3, cap reached
      described_class.new(profile_task: pt).call
      expect(ProfileTask.where(profile: profile, global_task: gt, status: :pending)).to be_empty
    end
  end

  describe "submission_comment" do
    let(:family) { create(:family, require_photo: false, auto_approve_threshold: nil) }
    let(:profile) { create(:profile, family: family, role: :child) }
    let(:profile_task) { create(:profile_task, profile: profile, status: :pending) }

    it "persists the comment on submission" do
      result = described_class.call(profile_task: profile_task, submission_comment: "  fiz com carinho  ")
      expect(result).to be_success
      expect(profile_task.reload.submission_comment).to eq("fiz com carinho")
    end

    it "treats blank comment as nil" do
      result = described_class.call(profile_task: profile_task, submission_comment: "   ")
      expect(result).to be_success
      expect(profile_task.reload.submission_comment).to be_nil
    end
  end
end
