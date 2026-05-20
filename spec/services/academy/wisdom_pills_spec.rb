# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::WisdomPills do
  before { described_class.reload! }

  describe ".all" do
    it "loads at least 120 curated pills from the YAML" do
      expect(described_class.all.size).to be >= 120
    end

    it "keeps the synthetic 'O Guia' voice to no more than 12 pills" do
      guia_count = described_class.all.count { |p| p.source == "O Guia" }
      expect(guia_count).to be <= 12
    end

    it "keeps the synthetic 'O Guia' voice under 10% of the pool" do
      total = described_class.all.size
      guia_count = described_class.all.count { |p| p.source == "O Guia" }
      expect(guia_count.to_f / total).to be <= 0.10
    end

    it "gives every pill a non-empty `text` (≤ 140 chars)" do
      described_class.all.each do |pill|
        expect(pill.text).to be_a(String)
        expect(pill.text).not_to be_empty
        expect(pill.text.length).to be <= 140, "Pílula longa demais (#{pill.text.length}): #{pill.text}"
      end
    end

    it "gives every pill a non-empty `source`" do
      described_class.all.each do |pill|
        expect(pill.source).to be_a(String)
        expect(pill.source).not_to be_empty
      end
    end

    it "accepts an optional `theme` (nil or one of the curated set)" do
      allowed = [ nil, "curiosidade", "escuta", "perseveranca", "humor", "coragem", "sabedoria" ]
      described_class.all.each do |pill|
        expect(allowed).to include(pill.theme), "Tema inesperado: #{pill.theme.inspect} em '#{pill.text}'"
      end
    end
  end

  describe ".sample" do
    it "returns a Pill with no arguments (backwards compatibility)" do
      pill = described_class.sample
      expect(pill).to be_a(Academy::WisdomPills::Pill)
      expect(pill.text).not_to be_empty
      expect(pill.source).not_to be_empty
    end

    it "returns a Pill when called with a known theme" do
      pill = described_class.sample(theme: :curiosidade)
      expect(pill).to be_a(Academy::WisdomPills::Pill)
    end

    it "respects `theme:` when the filtered pool has at least 5 pills" do
      curiosidade_count = described_class.all.count { |p| p.theme == "curiosidade" }
      next unless curiosidade_count >= 5

      # 30 samples — vanishingly small chance of a non-matching pill leak
      30.times do
        pill = described_class.sample(theme: :curiosidade)
        expect(pill.theme).to eq("curiosidade")
      end
    end

    it "falls back to uniform sample when the themed pool is too small" do
      # `:inexistente` has zero pills → must fall back without raising.
      pill = described_class.sample(theme: :inexistente)
      expect(pill).to be_a(Academy::WisdomPills::Pill)
    end

    it "accepts both Symbol and String for `theme:`" do
      expect { described_class.sample(theme: :sabedoria) }.not_to raise_error
      expect { described_class.sample(theme: "sabedoria") }.not_to raise_error
    end
  end

  describe "Pill data shape" do
    it "exposes :text, :source and :theme readers" do
      pill = described_class.all.first
      expect(pill).to respond_to(:text, :source, :theme)
    end
  end
end
