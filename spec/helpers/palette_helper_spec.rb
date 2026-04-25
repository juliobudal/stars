require "rails_helper"

RSpec.describe PaletteHelper, type: :helper do
  describe "#palette_for" do
    it "returns the profile's color when present" do
      profile = build_stubbed(:profile, color: "mint")
      expect(helper.palette_for(profile)).to eq("mint")
    end

    it "returns 'primary' when profile color is blank" do
      profile = build_stubbed(:profile, color: "")
      expect(helper.palette_for(profile)).to eq("primary")
    end

    it "returns 'primary' when profile color is nil" do
      profile = build_stubbed(:profile, color: nil)
      expect(helper.palette_for(profile)).to eq("primary")
    end

    it "returns 'primary' when profile is nil" do
      expect(helper.palette_for(nil)).to eq("primary")
    end
  end
end
