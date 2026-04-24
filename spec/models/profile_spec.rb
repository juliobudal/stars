# == Schema Information
#
# Table name: profiles
#
#  id              :bigint           not null, primary key
#  avatar          :string
#  color           :string
#  confirmed_at    :datetime
#  email           :citext
#  name            :string
#  password_digest :string
#  points          :integer          default(0)
#  role            :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  family_id       :bigint           not null
#
# Indexes
#
#  index_profiles_on_email_parent  (email) UNIQUE WHERE (role = 1)
#  index_profiles_on_family_id     (family_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#
require "rails_helper"

RSpec.describe Profile, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to have_many(:profile_tasks).dependent(:destroy) }
    it { is_expected.to have_many(:activity_logs).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_numericality_of(:points).is_greater_than_or_equal_to(0) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:role).with_values(child: 0, parent: 1) }
  end

  describe "parent email validations" do
    let(:family) { create(:family) }

    it "requires email for parent" do
      profile = build(:profile, :parent, family: family, email: nil)
      expect(profile).not_to be_valid
      expect(profile.errors[:email]).to be_present
    end

    it "requires valid email format for parent" do
      profile = build(:profile, :parent, family: family, email: "not-an-email")
      expect(profile).not_to be_valid
      expect(profile.errors[:email]).to be_present
    end

    it "enforces case-insensitive email uniqueness for parents" do
      create(:profile, :parent, family: family, email: "test@example.com")
      duplicate = build(:profile, :parent, family: family, email: "TEST@EXAMPLE.COM")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "does not require email for children" do
      profile = build(:profile, :child, family: family, email: nil)
      expect(profile).to be_valid
    end

    it "normalizes email to lowercase before validation" do
      profile = create(:profile, :parent, family: family, email: "UPPER@EXAMPLE.COM")
      expect(profile.email).to eq("upper@example.com")
    end
  end

  describe "parent password validations" do
    let(:family) { create(:family) }

    it "requires password on create for parent" do
      profile = build(:profile, :parent, family: family, password: nil)
      expect(profile).not_to be_valid
      expect(profile.errors[:password]).to be_present
    end

    it "requires password of at least 12 characters for parent" do
      profile = build(:profile, :parent, family: family, password: "short1234")
      expect(profile).not_to be_valid
      expect(profile.errors[:password]).to be_present
    end

    it "allows nil password on update for parent (no change)" do
      profile = create(:profile, :parent, family: family)
      profile.password = nil
      expect(profile).to be_valid
    end

    it "does not require password for children" do
      profile = build(:profile, :child, family: family)
      expect(profile).to be_valid
    end
  end
end
