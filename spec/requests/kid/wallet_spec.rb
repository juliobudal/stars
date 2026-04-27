require 'rails_helper'

RSpec.describe "Kid::Wallet week_start", type: :request do
  before { host! "localhost" }

  def login_as(profile)
    sign_in_as(profile)
  end

  describe "GET /kid/wallet with week_start = 0 (Sunday)" do
    it "renders day-group header for a Sunday log when family starts week on Sunday" do
      family = create(:family, week_start: 0)
      child  = create(:profile, :child, family: family)

      # Use a Sunday at least 2 days in the past to avoid "Hoje"/"Ontem" labels
      sunday = 2.weeks.ago.to_date.beginning_of_week(:sunday)

      create(:activity_log, :earn, profile: child, points: 5, title: "Tarefa Dom",
             created_at: sunday.to_time.in_time_zone + 10.hours)

      login_as(child)
      get kid_wallet_index_path

      expect(response).to have_http_status(:success)

      # The day-group header renders the date via l(date, format: :short).capitalize.
      # Assert that the rendered label for the Sunday date appears in the response body.
      sunday_label = I18n.l(sunday, format: :short).capitalize
      expect(response.body).to include(sunday_label)
    end
  end

  describe "GET /kid/wallet with week_start = 1 (Monday, default)" do
    it "renders correctly without Sunday grouping when family starts week on Monday" do
      family = create(:family, week_start: 1)
      child  = create(:profile, :child, family: family)

      monday = Date.current.beginning_of_week(:monday)
      create(:activity_log, :earn, profile: child, points: 7, title: "Tarefa Seg",
             created_at: monday.to_time.in_time_zone + 10.hours)

      login_as(child)
      get kid_wallet_index_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Tarefa Seg")
    end
  end
end
