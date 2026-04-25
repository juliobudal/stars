require "rails_helper"

RSpec.describe Auth::ResetPin do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }
  let(:other_family) { Family.create!(name: "Other", email: "o@x.co", password: "supersecret1234") }
  let(:parent) { family.profiles.create!(name: "Parent", role: :parent, pin: "1111") }
  let(:kid)    { family.profiles.create!(name: "Kid",    role: :child,  pin: "2222") }
  let(:foreign_parent) { other_family.profiles.create!(name: "Other Parent", role: :parent, pin: "3333") }

  it "lets parent reset own PIN" do
    result = described_class.call(profile: parent, new_pin: "4444", actor: parent)
    expect(result.success?).to be true
    expect(parent.reload.authenticate_pin("4444")).to be_truthy
  end

  it "lets parent reset kid PIN" do
    result = described_class.call(profile: kid, new_pin: "5555", actor: parent)
    expect(result.success?).to be true
    expect(kid.reload.authenticate_pin("5555")).to be_truthy
  end

  it "denies non-parent actor" do
    result = described_class.call(profile: kid, new_pin: "5555", actor: kid)
    expect(result.success?).to be false
  end

  it "denies cross-family target" do
    result = described_class.call(profile: foreign_parent, new_pin: "5555", actor: parent)
    expect(result.success?).to be false
  end

  it "rejects invalid PIN format" do
    result = described_class.call(profile: kid, new_pin: "abcd", actor: parent)
    expect(result.success?).to be false
  end
end
