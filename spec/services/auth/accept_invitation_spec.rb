require "rails_helper"

RSpec.describe Auth::AcceptInvitation do
  let(:family) { Family.create!(name: "Fam", email: "f@x.co", password: "supersecret1234") }
  let(:invitation) do
    family.profile_invitations.create!(
      email: "new@example.com", token: SecureRandom.hex(16),
      expires_at: 1.day.from_now
    )
  end

  it "marks invitation accepted and returns family" do
    result = described_class.call(token: invitation.token)
    expect(result.success?).to be true
    expect(result.family).to eq(family)
    expect(invitation.reload.accepted_at).to be_present
  end

  it "fails for unknown token" do
    result = described_class.call(token: "nope")
    expect(result.success?).to be false
  end

  it "fails for expired invitation" do
    invitation.update!(expires_at: 1.day.ago)
    result = described_class.call(token: invitation.token)
    expect(result.success?).to be false
  end

  it "fails for already-accepted invitation" do
    invitation.update!(accepted_at: 1.hour.ago)
    result = described_class.call(token: invitation.token)
    expect(result.success?).to be false
  end
end
