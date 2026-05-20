# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProfileInterest do
  let(:family)  { Family.create!(name: "Test", email: "t@t.test", password: "supersecret1") }
  let(:profile) { Profile.create!(family: family, name: "Kid", role: :child, pin: "1111") }

  describe "catalog" do
    it "loads keys from config/profile_interests.yml" do
      expect(ProfileInterest::Catalog.keys).to include("futebol", "dinossauros")
    end

    it "returns the canonical label for a known key" do
      expect(ProfileInterest::Catalog.label_for("futebol")).to eq("Futebol")
    end

    it "falls back to the raw key when unknown" do
      expect(ProfileInterest::Catalog.label_for("zzz-unknown")).to eq("zzz-unknown")
    end
  end

  describe "validations" do
    it "rejects an interest_key that is not in the catalog" do
      record = profile.profile_interests.build(interest_key: "not-a-real-thing", rank: 1)
      expect(record).not_to be_valid
      expect(record.errors[:interest_key]).to be_present
    end

    it "rejects duplicate keys for the same profile" do
      profile.profile_interests.create!(interest_key: "futebol", rank: 1)
      dup = profile.profile_interests.build(interest_key: "futebol", rank: 2)
      expect(dup).not_to be_valid
    end

    it "allows the same key across different profiles" do
      other = Profile.create!(family: family, name: "Kid2", role: :child, pin: "2222")
      profile.profile_interests.create!(interest_key: "futebol", rank: 1)
      expect(other.profile_interests.create(interest_key: "futebol", rank: 1)).to be_persisted
    end
  end

  describe "Profile#interest_keys" do
    it "returns keys ordered by rank" do
      profile.profile_interests.create!(interest_key: "futebol",     rank: 2)
      profile.profile_interests.create!(interest_key: "dinossauros", rank: 1)
      profile.profile_interests.create!(interest_key: "lego",        rank: 3)
      expect(profile.interest_keys(3)).to eq(%w[dinossauros futebol lego])
    end

    it "honors the limit argument" do
      %w[futebol gatos lego].each_with_index do |k, i|
        profile.profile_interests.create!(interest_key: k, rank: i + 1)
      end
      expect(profile.interest_keys(2).size).to eq(2)
    end
  end
end
