# frozen_string_literal: true

require "rails_helper"

RSpec.describe Academy::Illustrations::PromptComposer do
  describe "STYLE_VERSION" do
    it "is the current frozen style identifier" do
      expect(described_class::STYLE_VERSION).to eq("duolingo@v2")
    end
  end

  describe "PREFIX" do
    it "is frozen" do
      expect(described_class::PREFIX).to be_frozen
    end

    it "mentions the Duolingo green token" do
      expect(described_class::PREFIX).to include("#58CC02")
    end

    it "anchors a wordless picture book frame" do
      expect(described_class::PREFIX).to match(/wordless children's\s+picture book/m)
    end

    it "forbids letters, numbers, and words anywhere" do
      expect(described_class::PREFIX).to match(/no letters,\s*no numbers,\s*no words anywhere/)
    end

    it "fixes a square composition" do
      expect(described_class::PREFIX).to include("square 1:1")
    end
  end

  describe ".compose" do
    let(:hint) { "Ilustração de um olho humano com lente ajustável." }

    it "starts with the verbatim PREFIX" do
      result = described_class.compose(hint: hint)
      expect(result).to start_with(described_class::PREFIX)
    end

    it "appends the hint under a Scene: marker" do
      result = described_class.compose(hint: hint)
      expect(result).to include("\n\nScene: #{hint}")
    end

    it "is deterministic for the same hint" do
      expect(described_class.compose(hint: hint)).to eq(described_class.compose(hint: hint))
    end
  end
end
