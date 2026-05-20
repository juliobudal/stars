# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Lens::Voices do
  describe "ROSTER" do
    it "defines 5 sub-voices" do
      expect(described_class::ROSTER.keys).to match_array(
        %i[naturalist historian engineer translator judge]
      )
    end

    it "every voice has a name, emoji, tagline, tics, and system_extra" do
      described_class::ROSTER.each_value do |voice|
        expect(voice.name).to be_present
        expect(voice.emoji).to be_present
        expect(voice.tagline).to be_present
        expect(voice.tics).to be_an(Array).and(be_present)
        expect(voice.system_extra).to be_present
      end
    end
  end

  describe ".for_lens" do
    it "maps every catalog lens type to a voice" do
      Academy::Lens::Catalog::TYPES.each_key do |lens_type|
        voice = described_class.for_lens(lens_type)
        expect(voice).to be_a(described_class::Voice), "missing voice for #{lens_type}"
      end
    end

    it "maps historical to the Historiador" do
      expect(described_class.for_lens(:historical).key).to eq(:historian)
    end

    it "maps engineering to the Engenheira" do
      expect(described_class.for_lens(:engineering).key).to eq(:engineer)
    end

    it "returns nil for an unknown lens type" do
      expect(described_class.for_lens(:wat)).to be_nil
    end
  end
end
