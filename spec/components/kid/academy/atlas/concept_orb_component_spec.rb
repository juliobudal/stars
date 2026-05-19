# frozen_string_literal: true

require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Kid::Academy::Atlas::ConceptOrbComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:hero_concept) do
    build_stubbed(:academy_concept,
                   slug: "foco",
                   category: "cognitivo",
                   pokedex_color_key: "cognitivo",
                   pokedex_silhouette_key: "foco")
  end

  let(:plain_concept) do
    build_stubbed(:academy_concept,
                   slug: "concept-only-category",
                   category: "saude",
                   pokedex_color_key: "saude",
                   pokedex_silhouette_key: nil)
  end

  describe "visual states" do
    it "renders silhouette state at level 0" do
      render_inline(described_class.new(concept: hero_concept, level: 0))

      expect(page).to have_css(".pokedex-orb.pokedex-orb--silhouette")
      expect(page).to have_css("[data-level='0']")
      expect(page).to have_css("svg")
    end

    it "renders spotted state at level 1" do
      render_inline(described_class.new(concept: hero_concept, level: 1))
      expect(page).to have_css(".pokedex-orb--spotted[data-level='1']")
    end

    it "renders recognized state at level 2" do
      render_inline(described_class.new(concept: hero_concept, level: 2))
      expect(page).to have_css(".pokedex-orb--recognized[data-level='2']")
    end

    it "renders mastered state at level 3 (full color + glow)" do
      render_inline(described_class.new(concept: hero_concept, level: 3))
      expect(page).to have_css(".pokedex-orb--mastered[data-level='3']")
    end
  end

  describe "asset resolution" do
    it "inlines the hero silhouette SVG when pokedex_silhouette_key is set and asset exists" do
      result = render_inline(described_class.new(concept: hero_concept, level: 2))
      # The foco.svg asset is a target/bullseye — three concentric circles.
      circles = result.css("svg circle")
      expect(circles.length).to be >= 3
    end

    it "falls back to the category glyph when silhouette_key is nil" do
      result = render_inline(described_class.new(concept: plain_concept, level: 2))
      expect(result.css("svg").length).to eq(1)
    end

    it "falls back to category glyph when the silhouette_key points at a missing asset" do
      orphan = build_stubbed(:academy_concept,
                              slug: "no-such-hero",
                              pokedex_color_key: "tecnologia",
                              pokedex_silhouette_key: "ghost-slug-that-does-not-exist")
      result = render_inline(described_class.new(concept: orphan, level: 1))
      expect(result.css("svg").length).to eq(1)
    end
  end

  describe "color binding" do
    it "wires the color CSS variable from pokedex_color_key" do
      render_inline(described_class.new(concept: hero_concept, level: 2))
      orb = page.find(".pokedex-orb")
      expect(orb[:style]).to include("--academy-pokedex-cognitivo")
    end

    it "defaults to the cognitivo color when pokedex_color_key is missing" do
      bare = build_stubbed(:academy_concept,
                            slug: "bare",
                            pokedex_color_key: nil,
                            pokedex_silhouette_key: nil)
      render_inline(described_class.new(concept: bare, level: 0))
      expect(page.find(".pokedex-orb")[:style]).to include("--academy-pokedex-cognitivo")
    end
  end

  describe "accessibility + identity" do
    it "is aria-hidden and carries the concept slug for Stimulus targeting" do
      render_inline(described_class.new(concept: hero_concept, level: 1))
      orb = page.find(".pokedex-orb", visible: :all)
      expect(orb["aria-hidden"]).to eq("true")
      expect(orb["data-concept-slug"]).to eq("foco")
    end
  end
end
