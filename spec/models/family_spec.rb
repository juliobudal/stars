# == Schema Information
#
# Table name: families
#
#  id                     :bigint           not null, primary key
#  allow_negative         :boolean          default(FALSE)
#  auto_approve_threshold :integer
#  decay_enabled          :boolean          default(FALSE)
#  locale                 :string           default("pt-BR")
#  max_debt               :integer          default(100), not null
#  name                   :string
#  require_photo          :boolean          default(FALSE)
#  timezone               :string           default("America/Sao_Paulo")
#  week_start             :integer          default(1)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require "rails_helper"

RSpec.describe Family, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:profiles).dependent(:destroy) }
    it { is_expected.to have_many(:global_tasks).dependent(:destroy) }
    it { is_expected.to have_many(:rewards).dependent(:destroy) }
  end

  describe "credentials" do
    it "is invalid without email" do
      family = Family.new(name: "Test", password: "supersecret1234")
      expect(family).not_to be_valid
      expect(family.errors[:email]).to be_present
    end

    it "is invalid with malformed email" do
      family = Family.new(name: "Test", email: "nope", password: "supersecret1234")
      expect(family).not_to be_valid
      expect(family.errors[:email]).to be_present
    end

    it "rejects passwords shorter than 12 characters" do
      family = Family.new(name: "Test", email: "a@b.co", password: "short")
      expect(family).not_to be_valid
      expect(family.errors[:password]).to be_present
    end

    it "enforces unique email (case-insensitive)" do
      Family.create!(name: "A", email: "a@b.co", password: "supersecret1234")
      dup = Family.new(name: "B", email: "A@B.CO", password: "anothersecret1")
      expect(dup).not_to be_valid
      expect(dup.errors[:email]).to be_present
    end

    it "authenticates with correct password" do
      family = Family.create!(name: "A", email: "a@b.co", password: "supersecret1234")
      expect(family.authenticate("supersecret1234")).to eq(family)
      expect(family.authenticate("wrong")).to be_falsey
    end
  end
end
