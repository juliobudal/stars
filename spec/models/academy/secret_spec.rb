# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Secret do
  describe "associations" do
    it "belongs_to :mission (optional)" do
      reflection = described_class.reflect_on_association(:mission)
      expect(reflection.macro).to eq(:belongs_to)
      expect(reflection.class_name).to eq("Academy::Mission")
      expect(reflection.options[:optional]).to be(true)
    end

    it "has_many :unlocks (destroy)" do
      reflection = described_class.reflect_on_association(:unlocks)
      expect(reflection.macro).to eq(:has_many)
      expect(reflection.class_name).to eq("Academy::SecretUnlock")
      expect(reflection.options[:dependent]).to eq(:destroy)
    end
  end

  describe "validations" do
    it "requires slug and title" do
      record = described_class.new(rule: {})
      expect(record).not_to be_valid
      expect(record.errors[:slug]).to be_present
      expect(record.errors[:title]).to be_present
    end

    it "enforces slug uniqueness" do
      described_class.create!(slug: "secret-x", title: "T", rule: {})
      dup = described_class.new(slug: "secret-x", title: "Y", rule: {})
      expect(dup).not_to be_valid
    end
  end

  describe "enum :kind" do
    it "defines kind with the documented integer values" do
      expect(described_class.kinds).to eq(
        "cards_in_subject" => 0, "cards_total" => 1, "challenge_ratio" => 2
      )
    end
  end

  describe ".active" do
    it "filters active=true and orders by position then id" do
      on  = described_class.create!(slug: "active-secret-2", title: "On",  rule: {}, active: true,  position: 2)
      off = described_class.create!(slug: "active-secret-3", title: "Off", rule: {}, active: false, position: 0)
      on2 = described_class.create!(slug: "active-secret-1", title: "On2", rule: {}, active: true,  position: 1)

      ordered = described_class.active.where(id: [ on.id, off.id, on2.id ])
      expect(ordered).to eq([ on2, on ])
    end
  end
end
