require "rails_helper"

RSpec.describe ProfileTask, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to belong_to(:global_task) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, awaiting_approval: 1, approved: 2, rejected: 3) }
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:title).to(:global_task) }
    it { is_expected.to delegate_method(:points).to(:global_task) }
    it { is_expected.to delegate_method(:category).to(:global_task) }
  end

  describe "scopes" do
    describe ".for_today" do
      it "returns tasks assigned for today" do
        task_today = create(:profile_task, assigned_date: Date.current)
        task_yesterday = create(:profile_task, assigned_date: Date.yesterday)
        expect(ProfileTask.for_today).to include(task_today)
        expect(ProfileTask.for_today).not_to include(task_yesterday)
      end
    end

    describe ".actionable" do
      it "returns pending and awaiting_approval tasks" do
        pending_task = create(:profile_task, status: :pending)
        awaiting_task = create(:profile_task, status: :awaiting_approval)
        approved_task = create(:profile_task, status: :approved)

        expect(ProfileTask.actionable).to include(pending_task, awaiting_task)
        expect(ProfileTask.actionable).not_to include(approved_task)
      end
    end
  end

  describe "proof_photo validation" do
    let(:profile_task) { build(:profile_task) }

    def attach_photo(task, filename: "photo.jpg", content_type: "image/jpeg", size: 1.kilobyte)
      task.proof_photo.attach(
        io: StringIO.new("x" * size),
        filename: filename,
        content_type: content_type
      )
    end

    context "when no photo is attached" do
      it "is valid without a proof_photo" do
        expect(profile_task).to be_valid
      end
    end

    context "when a valid photo is attached" do
      it "accepts image/jpeg under 5 MB" do
        attach_photo(profile_task, content_type: "image/jpeg", size: 1.megabyte)
        expect(profile_task).to be_valid
      end

      it "accepts image/png under 5 MB" do
        attach_photo(profile_task, filename: "photo.png", content_type: "image/png", size: 1.megabyte)
        expect(profile_task).to be_valid
      end

      it "accepts image/webp under 5 MB" do
        attach_photo(profile_task, filename: "photo.webp", content_type: "image/webp", size: 1.megabyte)
        expect(profile_task).to be_valid
      end
    end

    context "when the photo is too large" do
      it "rejects a file larger than 5 MB" do
        attach_photo(profile_task, size: 5.megabytes + 1)
        expect(profile_task).not_to be_valid
        expect(profile_task.errors[:proof_photo]).to be_present
      end
    end

    context "when the photo has an invalid content type" do
      it "rejects a PDF file" do
        attach_photo(profile_task, filename: "document.pdf", content_type: "application/pdf", size: 100.kilobytes)
        expect(profile_task).not_to be_valid
        expect(profile_task.errors[:proof_photo]).to be_present
      end

      it "rejects a GIF file" do
        attach_photo(profile_task, filename: "animation.gif", content_type: "image/gif", size: 100.kilobytes)
        expect(profile_task).not_to be_valid
        expect(profile_task.errors[:proof_photo]).to be_present
      end
    end
  end
end
