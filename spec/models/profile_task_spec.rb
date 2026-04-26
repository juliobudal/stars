# == Schema Information
#
# Table name: profile_tasks
#
#  id             :bigint           not null, primary key
#  assigned_date  :date
#  completed_at   :datetime
#  status         :integer          default("pending")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  global_task_id :bigint           not null
#  profile_id     :bigint           not null
#
# Indexes
#
#  index_profile_tasks_on_global_task_id                (global_task_id)
#  index_profile_tasks_on_profile_id                    (profile_id)
#  index_profile_tasks_on_profile_id_and_assigned_date  (profile_id,assigned_date)
#  index_profile_tasks_on_profile_id_and_status         (profile_id,status)
#
# Foreign Keys
#
#  fk_rails_...  (global_task_id => global_tasks.id)
#  fk_rails_...  (profile_id => profiles.id)
#
require "rails_helper"

RSpec.describe ProfileTask, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to belong_to(:global_task).optional }
    it { is_expected.to belong_to(:custom_category).class_name("Category").optional }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, awaiting_approval: 1, approved: 2, rejected: 3) }
  end

  describe "scopes" do
    describe ".for_today" do
      it "returns tasks assigned for today by default" do
        task_today = create(:profile_task, assigned_date: Date.current)
        task_yesterday = create(:profile_task, assigned_date: Date.yesterday)
        expect(ProfileTask.for_today).to include(task_today)
        expect(ProfileTask.for_today).not_to include(task_yesterday)
      end

      it "accepts an explicit date argument" do
        specific_date = Date.new(2024, 1, 1)
        task_on_date = create(:profile_task, assigned_date: specific_date)
        task_today   = create(:profile_task, assigned_date: Date.current)
        expect(ProfileTask.for_today(specific_date)).to include(task_on_date)
        expect(ProfileTask.for_today(specific_date)).not_to include(task_today)
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

  describe "source enum and custom missions" do
    it "defaults to catalog" do
      pt = build(:profile_task)
      expect(pt.source).to eq("catalog")
    end

    describe "custom validations" do
      let(:custom) { build(:profile_task, :custom) }

      it "is valid with required custom fields" do
        expect(custom).to be_valid
      end

      it "requires custom_title when custom" do
        custom.custom_title = nil
        expect(custom).not_to be_valid
        expect(custom.errors[:custom_title]).to be_present
      end

      it "requires custom_points >= 1" do
        custom.custom_points = 0
        expect(custom).not_to be_valid
        expect(custom.errors[:custom_points]).to be_present
      end

      it "requires custom_points <= 1000" do
        custom.custom_points = 1001
        expect(custom).not_to be_valid
        expect(custom.errors[:custom_points]).to be_present
      end

      it "requires custom_category when custom" do
        custom.custom_category = nil
        expect(custom).not_to be_valid
        expect(custom.errors[:custom_category_id]).to be_present
      end

      it "rejects global_task on custom" do
        custom.global_task = create(:global_task)
        expect(custom).not_to be_valid
        expect(custom.errors[:global_task_id]).to be_present
      end
    end

    describe "catalog validations" do
      it "requires global_task when catalog" do
        pt = build(:profile_task, global_task: nil)
        expect(pt).not_to be_valid
        expect(pt.errors[:global_task_id]).to be_present
      end
    end

    describe "delegated readers" do
      it "returns custom_title for custom missions" do
        pt = build(:profile_task, :custom, custom_title: "Lavar carro")
        expect(pt.title).to eq("Lavar carro")
      end

      it "returns custom_points for custom missions" do
        pt = build(:profile_task, :custom, custom_points: 42)
        expect(pt.points).to eq(42)
      end

      it "returns custom_category for custom missions" do
        cat = create(:category)
        pt = build(:profile_task, :custom, custom_category: cat)
        expect(pt.category).to eq(cat)
      end

      it "returns global_task fields for catalog missions" do
        gt = create(:global_task, points: 17)
        pt = build(:profile_task, global_task: gt)
        expect(pt.points).to eq(17)
      end
    end
  end
end
