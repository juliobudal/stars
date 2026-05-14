# == Schema Information
#
# Table name: global_tasks
#
#  id                         :bigint           not null, primary key
#  active                     :boolean          default(TRUE), not null
#  category                   :integer
#  day_of_month               :integer
#  days_of_week               :string           default([]), is an Array
#  description                :text
#  frequency                  :integer
#  icon                       :string
#  max_completions_per_period :integer          default(1), not null
#  points                     :integer
#  title                      :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  family_id                  :bigint           not null
#
# Indexes
#
#  index_global_tasks_on_family_id  (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
require "rails_helper"

RSpec.describe GlobalTask, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to have_many(:profile_tasks).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_numericality_of(:points).is_greater_than(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:category).with_values(escola: 0, casa: 1, rotina: 2, saude: 3, outro: 4) }
    it { is_expected.to define_enum_for(:frequency).with_values(daily: 0, weekly: 1, monthly: 2, once: 3) }
  end

  describe "monthly validations" do
    context "when frequency is monthly" do
      subject(:task) { build(:global_task, frequency: :monthly) }

      it "requires day_of_month" do
        task.day_of_month = nil
        expect(task).not_to be_valid
        expect(task.errors[:day_of_month]).not_to be_empty
      end

      it "accepts day_of_month in 1..31" do
        task.day_of_month = 15
        expect(task).to be_valid
      end

      it "rejects day_of_month = 0" do
        task.day_of_month = 0
        expect(task).not_to be_valid
      end

      it "rejects day_of_month = 32" do
        task.day_of_month = 32
        expect(task).not_to be_valid
      end
    end

    context "when frequency is not monthly" do
      it "does not require day_of_month" do
        task = build(:global_task, frequency: :daily, day_of_month: nil)
        expect(task).to be_valid
      end
    end
  end

  describe "max_completions_per_period" do
    subject(:task) { build(:global_task, max_completions_per_period: 3) }

    it "is valid with a value between 1 and 20" do
      expect(task).to be_valid
    end

    it "rejects values below 1" do
      task.max_completions_per_period = 0
      expect(task).not_to be_valid
      expect(task.errors[:max_completions_per_period]).to be_present
    end

    it "rejects values above 20" do
      task.max_completions_per_period = 21
      expect(task).not_to be_valid
    end

    it "forces max=1 when frequency is once" do
      task = build(:global_task, frequency: :once, max_completions_per_period: 5)
      task.valid?
      expect(task.max_completions_per_period).to eq(1)
    end
  end

  describe "#repeatable?" do
    it "is false when max_completions_per_period is 1" do
      expect(build(:global_task, max_completions_per_period: 1).repeatable?).to be(false)
    end

    it "is true when max_completions_per_period is greater than 1" do
      expect(build(:global_task, max_completions_per_period: 2).repeatable?).to be(true)
    end
  end

  describe "assigned_profile_ids cross-family guard" do
    let(:family) { create(:family) }
    let(:other_family) { create(:family) }
    let!(:own_kid) { create(:profile, :child, family: family) }
    let!(:foreign_kid) { create(:profile, :child, family: other_family) }

    it "accepts profiles from the same family" do
      task = build(:global_task, family: family, assigned_profile_ids: [ own_kid.id ])
      expect(task).to be_valid
    end

    it "rejects profiles from another family" do
      task = build(:global_task, family: family, assigned_profile_ids: [ foreign_kid.id ])
      expect(task).not_to be_valid
      expect(task.errors[:assigned_profile_ids]).to be_present
    end

    it "rejects mixed family ids" do
      task = build(:global_task, family: family, assigned_profile_ids: [ own_kid.id, foreign_kid.id ])
      expect(task).not_to be_valid
    end
  end

  describe "after_update_commit cap reduction" do
    let(:family) { create(:family) }
    let!(:child)  { create(:profile, :child, family: family) }
    let!(:gt)     { create(:global_task, :daily, family: family, max_completions_per_period: 5) }

    it "expires orphan pending rows when the cap drops below current consumed count" do
      create(:profile_task, profile: child, global_task: gt, assigned_date: Date.current, status: :awaiting_approval)
      create(:profile_task, profile: child, global_task: gt, assigned_date: Date.current, status: :approved)
      pending = create(:profile_task, profile: child, global_task: gt, assigned_date: Date.current, status: :pending)

      gt.update!(max_completions_per_period: 2)

      expect(pending.reload.status).to eq("expired")
    end

    it "is a no-op when max_completions_per_period does not change" do
      pending = create(:profile_task, profile: child, global_task: gt, assigned_date: Date.current, status: :pending)
      expect { gt.update!(title: "Renamed") }.not_to change { ProfileTask.where(id: pending.id).count }
    end
  end
end
