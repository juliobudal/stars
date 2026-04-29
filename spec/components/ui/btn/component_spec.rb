require "rails_helper"
require "view_component/test_helpers"

RSpec.describe Ui::Btn::Component, type: :component do
  include ViewComponent::TestHelpers

  describe "variant rendering" do
    Ui::Btn::Component::VARIANTS.each do |variant|
      it "renders #{variant} variant with expected BEM modifier class" do
        render_inline(described_class.new(variant: variant)) { "Click" }
        expect(page.native.to_html).to include("ui-btn--#{variant}")
      end
    end
  end

  describe "element type based on url/method" do
    it "renders a <button> when no url is given" do
      render_inline(described_class.new) { "Button" }
      expect(page).to have_css("button", text: "Button")
      expect(page).not_to have_css("a")
      expect(page).not_to have_css("form")
    end

    it "renders an <a> (link_to) when url is given without method" do
      render_inline(described_class.new(url: "/somewhere")) { "Link" }
      expect(page).to have_css("a[href='/somewhere']", text: "Link")
      expect(page).not_to have_css("button")
    end

    it "renders a <form> (button_to) when url and method are given" do
      render_inline(described_class.new(url: "/resource", method: :delete)) { "Delete" }
      expect(page).to have_css("form")
      expect(page).to have_css("button[type='submit']")
      expect(page).not_to have_css("a")
    end
  end

  describe "size classes" do
    it "applies ui-btn--sm BEM modifier for size sm" do
      render_inline(described_class.new(size: "sm")) { "Small" }
      expect(page.native.to_html).to include("ui-btn--sm")
    end

    it "applies ui-btn--lg BEM modifier for size lg" do
      render_inline(described_class.new(size: "lg")) { "Large" }
      expect(page.native.to_html).to include("ui-btn--lg")
    end

    it "applies ui-btn--md BEM modifier for default size md" do
      render_inline(described_class.new) { "Default" }
      expect(page.native.to_html).to include("ui-btn--md")
    end
  end

  describe "block option" do
    it "adds w-full class when block: true" do
      render_inline(described_class.new(block: true)) { "Full" }
      expect(page.native.to_html).to include("w-full")
    end

    it "does not add w-full class by default" do
      render_inline(described_class.new) { "Normal" }
      # w-11 appears for icon size but not plain w-full for block; check it is absent
      html = page.native.to_html
      expect(html).not_to match(/\bw-full\b/)
    end
  end

  describe "type passthrough" do
    it "passes type: submit to the button element" do
      render_inline(described_class.new(type: "submit")) { "Submit" }
      expect(page).to have_css("button[type='submit']")
    end
  end

  describe "touch-target floor (WCAG 2.5.5)" do
    %w[sm md lg icon].each do |sz|
      it "size #{sz} renders with min-h-[44px] floor class" do
        render_inline(described_class.new(size: sz)) { "X" }
        expect(page.native.to_html).to include("min-h-[44px]")
      end
    end
  end
end
