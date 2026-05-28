# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Kid::Academy::Trails", type: :request do
  let(:family) { create(:family, password: "supersecret1234") }
  let(:child)  { create(:profile, :child, family: family, pin: "1234") }
  let!(:trail) { create(:academy_trail, title: "Trilha Teste") }
  let!(:l1) { create(:academy_lesson, trail: trail, position: 1, title: "Aula Um") }

  before { sign_in_as(child, pin: "1234") }

  it "lists active trails with progress on the home" do
    get kid_academy_root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Trilha Teste")
    expect(response.body).to include("0/1")
  end

  it "shows the trail's lessons" do
    get kid_academy_trail_path(trail)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Aula Um")
  end
end
