require "rails_helper"

RSpec.describe Auth::CreateFamily do
  describe ".call" do
    let(:valid_params) { { name: "Test Fam", email: "fam@example.com", password: "supersecret1234" } }

    it "creates a family on valid params" do
      result = described_class.call(valid_params)
      expect(result.success?).to be true
      expect(result.data).to be_persisted
      expect(result.data.email).to eq("fam@example.com")
    end

    it "fails on duplicate email" do
      Family.create!(valid_params)
      result = described_class.call(valid_params)
      expect(result.success?).to be false
      expect(result.error).to be_present
    end

    it "fails on weak password" do
      result = described_class.call(valid_params.merge(password: "short"))
      expect(result.success?).to be false
      expect(result.error).to match(/senha|password/i)
    end
  end
end
