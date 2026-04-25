require 'rails_helper'

RSpec.describe "Kid::Rewards", type: :request do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 100) }
  let(:reward) { create(:reward, family: family, cost: 50, title: "Sorvete") }

  before do
    host! "localhost"
    sign_in_as(child)
  end

  describe "GET /kid/rewards" do
    it "lists available rewards" do
      task_reward = reward
      get kid_rewards_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sorvete")
    end
  end

  describe "POST /kid/rewards/:id/redeem" do
    it "redeems a reward successfully" do
      task_reward = reward
      expect {
        post redeem_kid_reward_path(task_reward)
      }.to change { child.reload.points }.by(-50)

      expect(response).to redirect_to(kid_rewards_path)
    end

    it "fails to redeem if not enough points" do
      expensive_reward = create(:reward, family: family, cost: 200)
      expect {
        post redeem_kid_reward_path(expensive_reward)
      }.not_to change { child.reload.points }

      expect(response).to redirect_to(kid_rewards_path)
      expect(flash[:alert]).to be_present
    end
  end
end

RSpec.describe "Kid::Wallet", type: :request do
  let(:family) { create(:family) }
  let(:child) { create(:profile, :child, family: family) }
  let(:log) { create(:activity_log, :task_completed, profile: child, points: 10, title: "Lavar Louça") }

  before do
    host! "localhost"
    sign_in_as(child)
  end

  describe "GET /kid/wallet" do
    it "lists activity logs" do
      activity_log = log
      get kid_wallet_index_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Lavar Louça")
      expect(response.body).to include("+10")
    end
  end
end
