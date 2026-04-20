require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:child_profile) { create(:profile, :child, family: family) }

  describe "POST /sessions" do
    it "redirects parent to /parent dashboard" do
      post sessions_path, params: { profile_id: parent_profile.id }
      puts "STATUS: #{response.status}"
      puts response.body if response.status != 302
      expect(response).to redirect_to(parent_root_path)
    end

    it "redirects child to /kid dashboard" do
      post sessions_path, params: { profile_id: child_profile.id }
      expect(response).to redirect_to(kid_root_path)
    end
  end

  describe "DELETE /sessions" do
    it "clears the session and redirects to root" do
      post sessions_path, params: { profile_id: parent_profile.id }

      delete sessions_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "Protected Routes" do
    it "redirects unauthenticated users to root" do
      get parent_root_path
      puts response.body
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Por favor, selecione um perfil primeiro.")
    end

    it "prevents children from accessing parent dashboard" do
      post sessions_path, params: { profile_id: child_profile.id }
      get parent_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito para pais.")
    end

    it "prevents parents from accessing child dashboard" do
      post sessions_path, params: { profile_id: parent_profile.id }
      get kid_root_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Acesso restrito para filhos.")
    end
  end
end
