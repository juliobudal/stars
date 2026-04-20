require 'rails_helper'

RSpec.describe "Parent::Profiles", type: :request do
  before { host! "localhost" }

  let(:family)         { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:child_profile)  { create(:profile, :child,  family: family) }

  def login_as(profile)
    post sessions_path, params: { profile_id: profile.id }
  end

  describe "Access Control" do
    it "redirects to root if not logged in" do
      get new_parent_profile_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects to root if logged in as child" do
      login_as(child_profile)
      get new_parent_profile_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "CRUD as parent" do
    before { login_as(parent_profile) }

    describe "GET /parent/profiles/new" do
      it "renders the new form" do
        get new_parent_profile_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /parent/profiles" do
      context "with valid params" do
        it "creates a child profile and redirects to dashboard" do
          expect {
            post parent_profiles_path, params: { profile: { name: "Maria", avatar: "🦊" } }
          }.to change(Profile, :count).by(1)

          expect(response).to redirect_to(parent_root_path)
          created = Profile.last
          expect(created.name).to eq("Maria")
          expect(created.role).to eq("child")
          expect(created.family_id).to eq(family.id)
        end
      end

      context "with invalid params" do
        it "renders new with unprocessable_entity status" do
          expect {
            post parent_profiles_path, params: { profile: { name: "" } }
          }.not_to change(Profile, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /parent/profiles/:id/edit" do
      it "renders the edit form" do
        get edit_parent_profile_path(child_profile)
        expect(response).to have_http_status(:success)
      end

      it "returns 404 if trying to edit a parent profile" do
        parent2 = create(:profile, :parent, family: family)
        get edit_parent_profile_path(parent2)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /parent/profiles/:id" do
      it "updates the child profile and redirects" do
        patch parent_profile_path(child_profile), params: { profile: { name: "Maria Clara", avatar: "🐱" } }

        expect(response).to redirect_to(parent_root_path)
        expect(child_profile.reload.name).to eq("Maria Clara")
        expect(child_profile.reload.avatar).to eq("🐱")
      end

      it "cannot change role to parent" do
        patch parent_profile_path(child_profile), params: { profile: { name: "Maria Clara" } }
        expect(child_profile.reload.role).to eq("child")
      end
    end

    describe "DELETE /parent/profiles/:id" do
      it "destroys the child profile (cascade) and redirects" do
        child = create(:profile, :child, family: family)

        expect {
          delete parent_profile_path(child)
        }.to change(Profile, :count).by(-1)

        expect(response).to redirect_to(parent_root_path)
        expect(Profile.exists?(child.id)).to be false
      end
    end
  end
end
