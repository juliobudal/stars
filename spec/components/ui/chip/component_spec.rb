require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::Chip::Component, type: :component do
  include ViewComponent::TestHelpers

  describe "variant rendering" do
    Ui::Chip::Component::VARIANTS.each do |variant|
      it "renders #{variant} variant with expected classes" do
        render_inline(described_class.new(variant: variant)) { "Label" }
        html = page.native.to_html
        if variant == "outline"
          expect(html).to include("bg-white")
        elsif variant == "neutral"
          expect(html).to include("bg-surface-2")
        else
          expect(html).to include("bg-#{variant}-soft")
        end
        expect(page).to have_text("Label")
      end
    end
  end

  describe "size classes" do
    it "applies sm size classes" do
      render_inline(described_class.new(size: "sm")) { "x" }
      html = page.native.to_html
      expect(html).to include("font-extrabold")
      expect(html).to include("px-[10px]")
    end

    it "applies md size classes by default" do
      render_inline(described_class.new) { "x" }
      html = page.native.to_html
      expect(html).to include("font-bold")
      expect(html).to include("px-3")
    end
  end

  describe "uppercase option" do
    it "adds uppercase class when uppercase: true" do
      render_inline(described_class.new(uppercase: true)) { "x" }
      expect(page.native.to_html).to include("uppercase")
    end

    it "does not add uppercase class by default" do
      render_inline(described_class.new) { "x" }
      expect(page.native.to_html).not_to match(/\buppercase\b/)
    end
  end

  describe "block content" do
    it "renders block content inside the span" do
      render_inline(described_class.new(variant: "mint")) { "Block Text" }
      expect(page).to have_css("span", text: "Block Text")
    end
  end

  describe "base classes" do
    it "always includes inline-flex and rounded-full" do
      render_inline(described_class.new) { "x" }
      html = page.native.to_html
      expect(html).to include("inline-flex")
      expect(html).to include("rounded-full")
    end
  end
end
