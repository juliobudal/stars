# == Schema Information
#
# Table name: profiles
#
#  id         :bigint           not null, primary key
#  avatar     :string
#  color      :string
#  email      :citext
#  name       :string
#  pin_digest :string
#  points     :integer          default(0)
#  role       :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  family_id  :bigint           not null
#
# Indexes
#
#  index_profiles_on_family_id  (family_id)
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

  describe "PIN" do
    let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }

    it "stores a hashed pin_digest, never the plaintext PIN" do
      profile = Profile.create!(family: family, name: "Kid", role: :child, pin: "1234")
      expect(profile.pin_digest).to be_present
      expect(profile.pin_digest).not_to eq("1234")
    end

    it "authenticates with correct PIN" do
      profile = Profile.create!(family: family, name: "Kid", role: :child, pin: "1234")
      expect(profile.authenticate_pin("1234")).to be_truthy
      expect(profile.authenticate_pin("9999")).to be_falsey
    end

    it "requires a 4-digit numeric PIN" do
      profile = Profile.new(family: family, name: "Kid", role: :child, pin: "abcd")
      expect(profile).not_to be_valid
      expect(profile.errors[:pin]).to be_present
    end

    it "requires pin on create" do
      profile = Profile.new(family: family, name: "Kid", role: :child)
      expect(profile).not_to be_valid
      expect(profile.errors[:pin_digest]).to be_present
    end
  end
end
