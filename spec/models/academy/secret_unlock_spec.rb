# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::SecretUnlock do
  let(:secret) { Academy::Secret.create!(slug: "u-#{SecureRandom.hex(4)}", title: "S", rule: {}) }

  describe "associations" do
    it "belongs_to :secret" do
      reflection = described_class.reflect_on_association(:secret)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.class_name).to eq("Academy::Secret")
    end
  end

  describe "validations" do
    it "requires learner_id" do
      record = described_class.new(secret: secret, unlocked_at: Time.current)
      expect(record).not_to be_valid
      expect(record.errors[:learner_id]).to be_present
    end

    it "is unique per (learner_id, secret_id)" do
      described_class.create!(secret: secret, learner_id: 1, unlocked_at: Time.current)
      dup = described_class.new(secret: secret, learner_id: 1, unlocked_at: Time.current)
      expect(dup).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:unseen) { described_class.create!(secret: secret, learner_id: 1, unlocked_at: Time.current, seen: false) }
    let!(:seen)   { described_class.create!(secret: secret, learner_id: 2, unlocked_at: Time.current, seen: true) }

    it ".unseen filters seen=false" do
      expect(described_class.unseen.where(secret_id: secret.id)).to contain_exactly(unseen)
    end

    it ".for_learner scopes by learner_id" do
      expect(described_class.for_learner(1).where(secret_id: secret.id)).to contain_exactly(unseen)
    end
  end
end
