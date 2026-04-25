require "rails_helper"

RSpec.describe "Invitations (public)", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:inviter) { create(:profile, :parent, family: family) }

  describe "GET /invitations/:token/accept" do
    context "with an active token" do
      let(:invitation) { create(:profile_invitation, family: family, invited_by: inviter) }

      it "renders the acceptance form" do
        get invitation_acceptance_path(token: invitation.token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an expired token" do
      let(:invitation) { create(:profile_invitation, :expired, family: family, invited_by: inviter) }

      it "returns 404" do
        get invitation_acceptance_path(token: invitation.token)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an already-accepted token" do
      let(:invitation) { create(:profile_invitation, :accepted, family: family, invited_by: inviter) }

      it "returns 404" do
        get invitation_acceptance_path(token: invitation.token)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an unknown token" do
      it "returns 404" do
        get invitation_acceptance_path(token: "nonexistent-token")
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /invitations/:token/accept" do
    let(:invitation) { create(:profile_invitation, family: family, invited_by: inviter) }

    context "with an active token" do
      it "marks the invitation as accepted" do
        post accept_invitation_path(token: invitation.token)
        invitation.reload
        expect(invitation.accepted_at).to be_present
      end

      it "redirects to new parent profile (onboarding)" do
        post accept_invitation_path(token: invitation.token)
        expect(response).to redirect_to(new_parent_profile_path(onboarding: true, invited: true))
      end

      it "returns 404 on second attempt with the same token" do
        post accept_invitation_path(token: invitation.token)
        post accept_invitation_path(token: invitation.token)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an expired token" do
      let(:expired) { create(:profile_invitation, :expired, family: family, invited_by: inviter) }

      it "returns 404" do
        post accept_invitation_path(token: expired.token)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with an unknown token" do
      it "returns 404" do
        post accept_invitation_path(token: "nonexistent-token")
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
