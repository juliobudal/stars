require 'rails_helper'

RSpec.describe "Parent::Rewards", type: :request do
  before { host! "localhost" }

  let(:family)         { create(:family) }
  let(:parent_profile) { create(:profile, :parent, family: family) }
  let(:child_profile)  { create(:profile, :child,  family: family) }
  let!(:reward)        { create(:reward, family: family, title: "Sorvete", cost: 100, icon: "🍦") }

  def login_as(profile)
    sign_in_as(profile)
  end

  describe "Access Control" do
    it "redirects unauthenticated users to root" do
      get parent_rewards_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects child users to root" do
      login_as(child_profile)
      get parent_rewards_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "CRUD as parent" do
    before { login_as(parent_profile) }

    describe "GET /parent/rewards" do
      it "lists rewards" do
        get parent_rewards_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Sorvete")
        expect(response.body).to include("100")
      end
    end

    describe "GET /parent/rewards/new" do
      it "renders the new form" do
        get new_parent_reward_path
        expect(response).to have_http_status(:success)
      end
    end

    describe "POST /parent/rewards" do
      context "with valid params" do
        it "creates a reward and redirects" do
          expect {
            post parent_rewards_path, params: {
              reward: { title: "Viagem ao parque", cost: 200, icon: "🎡" }
            }
          }.to change(Reward, :count).by(1)

          expect(response).to redirect_to(parent_rewards_path)
          new_reward = Reward.last
          expect(new_reward.title).to eq("Viagem ao parque")
          expect(new_reward.cost).to eq(200)
          expect(new_reward.family_id).to eq(family.id)
        end
      end

      context "with invalid params" do
        it "renders new form with error on blank title" do
          expect {
            post parent_rewards_path, params: { reward: { title: "", cost: 50 } }
          }.not_to change(Reward, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "renders new form with error on zero cost" do
          expect {
            post parent_rewards_path, params: { reward: { title: "Presente", cost: 0 } }
          }.not_to change(Reward, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    describe "GET /parent/rewards/:id/edit" do
      it "renders the edit form" do
        get edit_parent_reward_path(reward)
        expect(response).to have_http_status(:success)
      end
    end

    describe "PATCH /parent/rewards/:id" do
      it "updates category and redirects" do
        patch parent_reward_path(reward), params: { reward: { title: "Sorvete de morango", cost: 120, category: "doce" } }
        expect(response).to redirect_to(parent_rewards_path)
        reward.reload
        expect(reward.title).to eq("Sorvete de morango")
        expect(reward.category).to eq("doce")
        expect(reward.cost).to eq(120)
      end
    end

    describe "DELETE /parent/rewards/:id" do
      it "destroys the reward and redirects" do
        expect {
          delete parent_reward_path(reward)
        }.to change(Reward, :count).by(-1)

        expect(response).to redirect_to(parent_rewards_path)
        expect(Reward.exists?(reward.id)).to be false
      end

      it "cannot destroy a reward from another family" do
        other_family = create(:family)
        other_reward = create(:reward, family: other_family, title: "Other", cost: 50)

        delete parent_reward_path(other_reward)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
