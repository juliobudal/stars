require 'rails_helper'

# Guards against runtime gaps that unit/component specs miss: a route that 500s
# in a real request cycle (lazy-autoload constant errors, nil derefs on empty
# data, missing partials). Regression anchor for the Academy::Interest autoload
# fix — that one only fired for a kid WITH interests, in a real request.
RSpec.describe "Route smoke (no 5xx)", type: :request do
  before { host! "localhost" }

  let(:family) { create(:family) }

  # A kid WITH interests so Kid::Academy::BaseController#build_learner actually
  # references ::Academy::Interest — the path that regressed under dev autoload.
  let(:kid) do
    create(:profile, :child, family: family).tap do |p|
      p.profile_interests.create!(interest_key: "dinossauros", rank: 0)
      p.profile_interests.create!(interest_key: "cachorros", rank: 1)
    end
  end

  let(:parent) { create(:profile, :parent, family: family) }

  def expect_no_server_error(path)
    get path
    expect(response.status).to be < 500, "GET #{path} returned #{response.status}"
  end

  context "as a kid with interests" do
    before { sign_in_as(kid) }

    it "renders every main kid surface without a server error" do
      [
        kid_root_path,
        kid_wallet_index_path,
        kid_rewards_path,
        kid_interests_path,
        kid_academy_root_path,
        new_kid_mission_path
      ].each { |path| expect_no_server_error(path) }
    end
  end

  context "as a parent" do
    before { sign_in_as(parent) }

    it "renders every main parent surface without a server error" do
      [
        parent_root_path,
        parent_profiles_path,
        parent_global_tasks_path,
        library_parent_global_tasks_path,
        parent_rewards_path,
        parent_categories_path,
        parent_approvals_path,
        parent_settings_path,
        parent_activity_logs_path,
        parent_academy_dashboard_path
      ].each { |path| expect_no_server_error(path) }
    end
  end
end
