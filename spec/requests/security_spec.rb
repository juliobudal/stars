require 'rails_helper'

RSpec.describe "Security Access", type: :request do
  let(:family) { create(:family) }
  let(:parent) { create(:profile, :parent, family: family) }
  let(:child) { create(:profile, :child, family: family) }

  before { host! "localhost" }

  describe "Parent namespace" do
    it "denies access to children" do
      sign_in_as(child)
      get parent_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Acesso restrito para pais")
    end
  end

  describe "Kid namespace" do
    it "denies access to parents" do
      sign_in_as(parent)
      get kid_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include("Acesso restrito para filhos")
    end
  end

  describe "Unauthenticated" do
    it "denies access to parent pages" do
      get parent_root_path
      expect(response).to redirect_to(new_family_session_path)
    end

    it "denies access to kid pages" do
      get kid_root_path
      expect(response).to redirect_to(new_family_session_path)
    end
  end
end
