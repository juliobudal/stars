require "rails_helper"

RSpec.describe InvitationMailer, type: :mailer do
  describe "#invite" do
    let(:family) { create(:family, name: "Silva") }
    let(:inviter) { create(:profile, :parent, family: family) }
    let(:invitation) { create(:profile_invitation, family: family, invited_by: inviter, email: "newparent@example.com") }
    let(:raw_token) { invitation.raw_token }
    let(:mail) { InvitationMailer.invite(invitation, raw_token) }

    it "delivers to the invitation email" do
      expect(mail.to).to eq([ "newparent@example.com" ])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Junte-se à família Silva")
    end

    it "includes the acceptance link in the text body" do
      expect(mail.text_part.body.to_s).to include(raw_token)
    end

    it "includes the acceptance link in the html body" do
      expect(mail.html_part.body.to_s).to include(raw_token)
    end
  end
end
