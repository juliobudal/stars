require "rails_helper"

RSpec.describe "Parent::Categories", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:child_profile) { create(:profile, :child, family: family) }

  describe "Access Control" do
    it "redirects unauthenticated to login" do
      get parent_categories_path
      expect(response).to redirect_to(new_family_session_path)
    end

    it "redirects child users" do
      sign_in_as(child_profile)
      get parent_categories_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as parent" do
    before { sign_in_as(parent_profile) }

    describe "GET /parent/categories" do
      it "lists current family's categories" do
        get parent_categories_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Telinha")
      end
    end

    describe "POST /parent/categories" do
      it "creates a category" do
        expect {
          post parent_categories_path, params: {
            category: { name: "Música", icon: "bookmark-01", color: "violet" }
          }
        }.to change { family.categories.count }.by(1)
        expect(response).to redirect_to(parent_categories_path)
      end
    end

    describe "PATCH /parent/categories/:id" do
      it "updates the category" do
        cat = family.categories.first
        patch parent_category_path(cat),
              params: { category: { name: "Tela & Jogos", icon: cat.icon, color: cat.color } }
        expect(cat.reload.name).to eq("Tela & Jogos")
      end
    end

    describe "DELETE /parent/categories/:id" do
      it "destroys an empty category" do
        cat = create(:category, family: family, name: "Vazia")
        expect {
          delete parent_category_path(cat)
        }.to change { family.categories.count }.by(-1)
      end

      it "blocks delete when rewards are attached" do
        cat = family.categories.first
        create(:reward, family: family, category: cat)
        expect {
          delete parent_category_path(cat)
        }.not_to change { family.categories.count }
        follow_redirect!
        expect(response.body).to match(/reatribua/i)
      end

      it "returns 404 for cross-family access" do
        other = create(:category, family: create(:family))
        delete parent_category_path(other)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
