# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::MascotReaction do
  describe ".for" do
    it "returns a correct-tier reaction for a known lens_type" do
      r = described_class.for(lens_type: :scientific, correct: true, seed: "abc")
      expect(r).to be_a(described_class::Reaction)
      expect(r.tier).to eq(:correct)
      expect(r.emoji).to eq(described_class::EMOJI)
      expect(r.text).to be_present
    end

    it "returns a wrong-tier reaction for a known lens_type" do
      r = described_class.for(lens_type: :scientific, correct: false, seed: "abc")
      expect(r.tier).to eq(:wrong)
      expect(r.text).to be_present
    end

    it "is deterministic — same lens_type + correct + seed always returns the same line" do
      a = described_class.for(lens_type: :ethical, correct: true, seed: "fixed-seed")
      b = described_class.for(lens_type: :ethical, correct: true, seed: "fixed-seed")
      expect(a.text).to eq(b.text)
    end

    it "returns different lines for different seeds when the pool has variety" do
      texts = (1..50).map { |i| described_class.for(lens_type: :scientific, correct: true, seed: "seed-#{i}").text }
      expect(texts.uniq.size).to be >= 2
    end

    it "falls back to default pool for unknown lens_types" do
      r = described_class.for(lens_type: :unknown_type, correct: true, seed: "x")
      expect(r.text).to be_present
      default_correct = described_class::POOL[:default][:correct]
      expect(default_correct).to include(r.text)
    end

    it "accepts a string lens_type" do
      r = described_class.for(lens_type: "scientific", correct: true, seed: "x")
      expect(r).to be_a(described_class::Reaction)
    end

    it "accepts an integer seed" do
      r = described_class.for(lens_type: :scientific, correct: true, seed: 12_345)
      expect(r.text).to be_present
    end
  end

  describe "POOL coverage" do
    it "has correct + wrong buckets for every catalog lens type" do
      catalog_types = Academy::Lens::Catalog::TYPES.keys
      catalog_types.each do |lens_type|
        bucket = described_class::POOL[lens_type] || described_class::POOL[:default]
        expect(bucket[:correct]).to be_an(Array).and(be_present), "missing :correct pool for #{lens_type}"
        expect(bucket[:wrong]).to be_an(Array).and(be_present),   "missing :wrong pool for #{lens_type}"
      end
    end

    it "has at least 3 lines per bucket so the deterministic pick has variety" do
      described_class::POOL.each do |lens_type, bucket|
        expect(bucket[:correct].size).to be >= 3, "lens_type=#{lens_type} :correct has #{bucket[:correct].size}"
        expect(bucket[:wrong].size).to   be >= 3, "lens_type=#{lens_type} :wrong has #{bucket[:wrong].size}"
      end
    end
  end

  describe ".stable_index" do
    it "returns 0 when modulo is 0 or 1" do
      expect(described_class.stable_index("any", 0)).to eq(0)
      expect(described_class.stable_index("any", 1)).to eq(0)
    end

    it "is stable for the same string seed" do
      idx1 = described_class.stable_index("hello", 10)
      idx2 = described_class.stable_index("hello", 10)
      expect(idx1).to eq(idx2)
    end

    it "respects the modulo boundary" do
      100.times do |i|
        idx = described_class.stable_index("seed-#{i}", 7)
        expect(idx).to be_between(0, 6)
      end
    end
  end
end
