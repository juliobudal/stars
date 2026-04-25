require "rails_helper"

RSpec.describe "Parent::Invitations", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }

  describe "GET /parent/invitations/new" do
    context "when authenticated as parent" do
      before { sign_in_as(parent_profile) }

      it "renders the new invitation form" do
        get new_parent_invitation_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get new_parent_invitation_path
        expect(response).to redirect_to(new_family_session_path)
      end
    end
  end

  describe "POST /parent/invitations" do
    context "when authenticated as parent" do
      before { sign_in_as(parent_profile) }

      it "creates an invitation and enqueues the mailer" do
        expect {
          post parent_invitations_path, params: { profile_invitation: { email: "newparent@example.com" } }
        }.to change(ProfileInvitation, :count).by(1)
           .and have_enqueued_mail(InvitationMailer, :invite)

        expect(response).to redirect_to(parent_settings_path)
        follow_redirect!
        expect(response.body).to include("Convite enviado")
      end

      it "renders new with errors for invalid email" do
        post parent_invitations_path, params: { profile_invitation: { email: "not-an-email" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        post parent_invitations_path, params: { profile_invitation: { email: "x@example.com" } }
        expect(response).to redirect_to(new_family_session_path)
      end
    end
  end
end
