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

    context "with valid params" do
      let(:valid_params) { { name: "Maria", password: "supersecret1234", password_confirmation: "supersecret1234" } }

      it "creates a new parent profile" do
        # force inviter + invitation to exist before counting
        invitation
        expect {
          post accept_invitation_path(token: invitation.token), params: valid_params
        }.to change(Profile, :count).by(1)
      end

      it "sets the session to the new profile" do
        post accept_invitation_path(token: invitation.token), params: valid_params
        new_profile = Profile.last
        expect(session[:profile_id]).to eq(new_profile.id)
      end

      it "redirects to parent root" do
        post accept_invitation_path(token: invitation.token), params: valid_params
        expect(response).to redirect_to(parent_root_path)
      end

      it "marks the invitation as accepted (single-use)" do
        post accept_invitation_path(token: invitation.token), params: valid_params
        invitation.reload
        expect(invitation.accepted_at).to be_present
      end

      it "returns 404 on second attempt with the same token" do
        post accept_invitation_path(token: invitation.token), params: valid_params
        # Second attempt — token is now accepted (no longer active)
        post accept_invitation_path(token: invitation.token), params: valid_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with missing name" do
      it "re-renders show with error" do
        post accept_invitation_path(token: invitation.token),
             params: { name: "", password: "supersecret1234", password_confirmation: "supersecret1234" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with mismatched passwords" do
      it "re-renders show with error" do
        post accept_invitation_path(token: invitation.token),
             params: { name: "Maria", password: "supersecret1234", password_confirmation: "different" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with an expired token" do
      let(:expired) { create(:profile_invitation, :expired, family: family, invited_by: inviter) }

      it "returns 404" do
        post accept_invitation_path(token: expired.token),
             params: { name: "Maria", password: "supersecret1234", password_confirmation: "supersecret1234" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
