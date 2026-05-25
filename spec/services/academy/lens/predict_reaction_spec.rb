# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::PredictReaction do
  def reaction(guess:, real:, range_min: 0, range_max: 100)
    described_class.call(guess: guess, real: real, range_min: range_min, range_max: range_max)
  end

  describe "tier bands (delta as % of range)" do
    it "returns :bullseye when guess is within 2% of range" do
      expect(reaction(guess: 50, real: 50).tier).to eq(:bullseye)
      expect(reaction(guess: 50, real: 51).tier).to eq(:bullseye)
    end

    it "returns :close when delta is 2–5% of range" do
      expect(reaction(guess: 50, real: 53).tier).to eq(:close)
      expect(reaction(guess: 50, real: 55).tier).to eq(:close)
    end

    it "returns :off when delta is 5–20% of range" do
      expect(reaction(guess: 50, real: 60).tier).to eq(:off)
      expect(reaction(guess: 50, real: 70).tier).to eq(:off)
    end

    it "returns :way_off when delta is 20–50% of range" do
      expect(reaction(guess: 50, real: 75).tier).to eq(:way_off)
      expect(reaction(guess: 10, real: 60).tier).to eq(:way_off)
    end

    it "returns :astronomical when delta exceeds 50% of range" do
      expect(reaction(guess: 0, real: 100).tier).to eq(:astronomical)
      expect(reaction(guess: 95, real: 5).tier).to eq(:astronomical)
    end
  end

  describe "real-world predict cases (probabilidade-do-dado.json)" do
    it "treats a 10% guess on 0.1% real as :off (10pp delta is 10% of range)" do
      expect(reaction(guess: 10, real: 0.1).tier).to eq(:off)
    end

    it "treats a 50% guess on 0.1% real as :way_off" do
      expect(reaction(guess: 50, real: 0.1).tier).to eq(:way_off)
    end

    it "treats a 1% guess on 0.1% real as :bullseye (delta is 0.9pp)" do
      expect(reaction(guess: 1, real: 0.1).tier).to eq(:bullseye)
    end
  end

  describe "content payload" do
    it "ships emoji + headline + detail for every tier" do
      described_class::TIERS.each do |tier|
        sample = case tier
        when :bullseye      then reaction(guess: 50, real: 50)
        when :close         then reaction(guess: 50, real: 54)
        when :off           then reaction(guess: 50, real: 65)
        when :way_off       then reaction(guess: 50, real: 80)
        when :astronomical  then reaction(guess: 5, real: 95)
        end
        expect(sample.tier).to eq(tier)
        expect(sample.emoji).to be_present
        expect(sample.headline).to be_present
        expect(sample.detail).to be_present
      end
    end

    it "annotates :way_off and :astronomical with a multiplier when both values are positive" do
      r = reaction(guess: 50, real: 0.1)
      expect(r.tier).to eq(:way_off)
      expect(r.detail).to match(/\d+× a mais/)
    end

    it "gracefully omits multiplier annotation when real is zero" do
      r = reaction(guess: 80, real: 0)
      expect(r.tier).to eq(:astronomical)
      expect(r.detail).not_to match(/Infinity/)
    end
  end

  describe "edge cases" do
    it "handles a zero-width range without dividing by zero" do
      expect { reaction(guess: 5, real: 5, range_min: 0, range_max: 0) }.not_to raise_error
    end

    it "annotates direction 'a mais' when guess > real" do
      r = reaction(guess: 50, real: 5)
      expect(r.detail).to include("a mais")
    end

    it "annotates direction 'a menos' when guess < real" do
      r = reaction(guess: 5, real: 50)
      expect(r.detail).to include("a menos")
    end
  end
end
