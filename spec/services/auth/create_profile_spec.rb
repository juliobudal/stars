require "rails_helper"

RSpec.describe Auth::CreateProfile do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }

  it "creates a profile with hashed PIN" do
    result = described_class.call(family: family, params: { name: "Kid", role: :child }, pin: "1234")
    expect(result.success?).to be true
    expect(result.profile).to be_persisted
    expect(result.profile.authenticate_pin("1234")).to be_truthy
  end

  it "fails on invalid PIN format" do
    result = described_class.call(family: family, params: { name: "Kid", role: :child }, pin: "abcd")
    expect(result.success?).to be false
    expect(result.error).to be_present
  end

  it "fails when name missing" do
    result = described_class.call(family: family, params: { name: "", role: :child }, pin: "1234")
    expect(result.success?).to be false
  end
end
