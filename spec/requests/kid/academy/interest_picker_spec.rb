# frozen_string_literal: true

require "rails_helper"

# Interest Picker end-to-end (Plan F). Renders the kid's "Eu curto" page,
# validates 3-5 picks from the canonical catalog, persists them as
# ProfileInterest rows ranked by selection order.
RSpec.describe "Kid interests picker", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }

  before { sign_in_as(child, pin: "1234") }

  it "renders the picker with the canonical catalog" do
    get kid_interests_path

    expect(response).to have_http_status(:ok)
    expect(ProfileInterest::Catalog.all).not_to be_empty
    expect(response.body).to include(ProfileInterest::Catalog.all.first.label)
  end

  it "persists picks ranked by click order and redirects to root" do
    keys = ProfileInterest::Catalog.all.first(3).map(&:key)

    expect {
      patch kid_interests_path, params: { interest_keys: keys }
    }.to change { child.reload.profile_interests.count }.from(0).to(3)

    expect(response).to redirect_to(kid_root_path)
    follow_redirect!
    expect(response.body).to include("salvei seus gostos")
    expect(child.reload.profile_interests.order(:rank).pluck(:interest_key)).to eq(keys)
  end

  it "rejects fewer than the minimum number of picks" do
    keys = [ ProfileInterest::Catalog.all.first.key ]

    expect {
      patch kid_interests_path, params: { interest_keys: keys }
    }.not_to change { child.reload.profile_interests.count }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("ao menos")
  end

  it "caps picks at the maximum" do
    keys = ProfileInterest::Catalog.all.first(10).map(&:key)

    patch kid_interests_path, params: { interest_keys: keys }

    expect(response).to redirect_to(kid_root_path)
    expect(child.reload.profile_interests.count)
      .to eq(Kid::InterestsController::MAX_PICKS)
  end

  it "replaces existing picks rather than appending" do
    initial = ProfileInterest::Catalog.all.first(3).map(&:key)
    patch kid_interests_path, params: { interest_keys: initial }
    expect(child.reload.profile_interests.count).to eq(3)

    replacement = ProfileInterest::Catalog.all.last(3).map(&:key)
    patch kid_interests_path, params: { interest_keys: replacement }

    expect(child.reload.profile_interests.order(:rank).pluck(:interest_key))
      .to eq(replacement)
  end
end
