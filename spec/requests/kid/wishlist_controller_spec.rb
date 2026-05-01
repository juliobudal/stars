require "rails_helper"

RSpec.describe "Kid::Wishlist", type: :request do
  let(:family) { create(:family) }
  let(:other_family) { create(:family) }
  let(:child) { create(:profile, :child, family: family, points: 30) }
  let(:reward) { create(:reward, family: family, cost: 100, title: "LEGO") }
  let(:foreign_reward) { create(:reward, family: other_family, cost: 100) }

  context "when signed in as the child" do
    before do
      host! "localhost"
      sign_in_as(child)
    end

    describe "POST /kid/wishlist" do
      it "sets wishlist_reward and redirects to kid_rewards_path" do
        expect {
          post kid_wishlist_path, params: { reward_id: reward.id }
        }.to change { child.reload.wishlist_reward_id }.from(nil).to(reward.id)

        expect(response).to redirect_to(kid_rewards_path)
        follow_redirect!
        expect(flash[:notice]).to match(/Meta atualizada/i)
      end

      it "rejects a cross-family reward_id (RecordNotFound short-circuits)" do
        expect {
          post kid_wishlist_path, params: { reward_id: foreign_reward.id }
        }.not_to change { child.reload.wishlist_reward_id }

        expect(response.status).to be_in([ 302, 404 ])
      end

      it "rejects a missing reward_id (RecordNotFound on find)" do
        expect {
          post kid_wishlist_path, params: { reward_id: 999_999 }
        }.not_to change { child.reload.wishlist_reward_id }

        expect(response.status).to be_in([ 302, 404 ])
      end
    end

    describe "DELETE /kid/wishlist" do
      before { child.update!(wishlist_reward: reward) }

      it "clears wishlist_reward and redirects" do
        expect {
          delete kid_wishlist_path
        }.to change { child.reload.wishlist_reward_id }.from(reward.id).to(nil)

        expect(response).to redirect_to(kid_rewards_path)
        follow_redirect!
        expect(flash[:notice]).to match(/Meta removida/i)
      end
    end
  end

  context "when not signed in" do
    it "POST does not change wishlist and does not 200" do
      host! "localhost"
      expect {
        post kid_wishlist_path, params: { reward_id: reward.id }
      }.not_to change { child.reload.wishlist_reward_id }

      expect(response).not_to have_http_status(:ok)
    end
  end
end
