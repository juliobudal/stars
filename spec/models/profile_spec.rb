# == Schema Information
#
# Table name: profiles
#
#  id                 :bigint           not null, primary key
#  avatar             :string
#  color              :string
#  email              :citext
#  name               :string
#  pin_digest         :string
#  points             :integer          default(0)
#  role               :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  family_id          :bigint           not null
#  wishlist_reward_id :bigint
#
# Indexes
#
#  index_profiles_on_family_id           (family_id)
#  index_profiles_on_wishlist_reward_id  (wishlist_reward_id)
#
# Foreign Keys
#
#  fk_rails_...  (family_id => families.id)
#  fk_rails_...  (wishlist_reward_id => rewards.id) ON DELETE => nullify
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

  describe "wishlist" do
    let(:family) { create(:family) }
    let(:child) { create(:profile, :child, family: family, points: 30) }
    let(:reward) { create(:reward, family: family, cost: 100) }

    describe "#wishlist_reward association" do
      it "is nil by default" do
        expect(child.wishlist_reward).to be_nil
      end

      it "returns the associated Reward when set" do
        child.update!(wishlist_reward: reward)
        expect(child.reload.wishlist_reward).to eq(reward)
      end

      it "is optional (no validation error when nil)" do
        expect { child.update!(wishlist_reward: nil) }.not_to raise_error
        expect(child.reload).to be_valid
      end
    end

    describe "nullify on Reward delete" do
      before { child.update!(wishlist_reward: reward) }

      it "sets wishlist_reward_id to NULL when the Reward is destroyed" do
        reward.destroy!
        expect(child.reload.wishlist_reward_id).to be_nil
      end
    end

    describe "#broadcast_wishlist_card callback" do
      it "broadcasts to kid_<id> when points change" do
        expect {
          child.update!(points: child.points + 5)
        }.to have_broadcasted_to("kid_#{child.id}")
      end

      it "broadcasts to kid_<id> when wishlist_reward changes" do
        expect {
          child.update!(wishlist_reward: reward)
        }.to have_broadcasted_to("kid_#{child.id}")
      end

      it "does not broadcast when an unrelated attribute changes" do
        expect {
          child.update!(name: "Novo Nome")
        }.not_to have_broadcasted_to("kid_#{child.id}")
      end
    end
  end
end
