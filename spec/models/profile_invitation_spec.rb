require "rails_helper"

RSpec.describe ProfileInvitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:family) }
    it { is_expected.to belong_to(:invited_by).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }

    it "rejects invalid email format" do
      inv = build(:profile_invitation, email: "not-an-email")
      expect(inv).not_to be_valid
      expect(inv.errors[:email]).to be_present
    end

    it "accepts a valid email" do
      inv = build(:profile_invitation, email: "valid@example.com")
      expect(inv).to be_valid
    end

    it "rejects duplicate tokens" do
      existing = create(:profile_invitation)
      inv = build(:profile_invitation, token: existing.token)
      expect(inv).not_to be_valid
      expect(inv.errors[:token]).to be_present
    end
  end

  describe "before_validation callbacks on create" do
    it "auto-generates a token" do
      inv = build(:profile_invitation, token: nil)
      inv.valid?
      expect(inv.token).to be_present
      expect(inv.token.length).to be >= 32
    end

    it "sets expires_at to 7 days from now if blank" do
      inv = build(:profile_invitation, expires_at: nil)
      inv.valid?
      expect(inv.expires_at).to be_within(5.seconds).of(7.days.from_now)
    end

    it "does not override a manually set expires_at" do
      future = 3.days.from_now
      inv = build(:profile_invitation, expires_at: future)
      inv.valid?
      expect(inv.expires_at).to be_within(1.second).of(future)
    end
  end

  describe ".active scope" do
    let(:family) { create(:family) }
    let(:inviter) { create(:profile, :parent, family: family) }

    it "includes pending non-expired invitations" do
      inv = create(:profile_invitation, family: family, invited_by: inviter)
      expect(ProfileInvitation.active).to include(inv)
    end

    it "excludes accepted invitations" do
      inv = create(:profile_invitation, :accepted, family: family, invited_by: inviter)
      expect(ProfileInvitation.active).not_to include(inv)
    end

    it "excludes expired invitations" do
      inv = create(:profile_invitation, :expired, family: family, invited_by: inviter)
      expect(ProfileInvitation.active).not_to include(inv)
    end
  end

  describe "#accept!" do
    let(:family) { create(:family) }
    let(:inviter) { create(:profile, :parent, family: family) }
    let(:invitation) { create(:profile_invitation, family: family, invited_by: inviter) }

    it "creates a parent profile with the given name and password" do
      # ensure inviter is created before counting
      inviter
      expect {
        invitation.accept!(name: "Maria", password: "supersecret1234")
      }.to change(Profile, :count).by(1)

      profile = Profile.last
      expect(profile.name).to eq("Maria")
      expect(profile.parent?).to be true
      expect(profile.family).to eq(family)
      expect(profile.confirmed_at).to be_present
    end

    it "marks the invitation as accepted" do
      invitation.accept!(name: "Maria", password: "supersecret1234")
      expect(invitation.reload.accepted_at).to be_present
    end

    it "returns the new profile" do
      profile = invitation.accept!(name: "Maria", password: "supersecret1234")
      expect(profile).to be_a(Profile)
      expect(profile.persisted?).to be true
    end

    it "raises ActiveRecord::RecordInvalid on invalid data" do
      expect {
        invitation.accept!(name: "", password: "supersecret1234")
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
