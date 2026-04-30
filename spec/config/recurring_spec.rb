require 'rails_helper'
require 'yaml'

RSpec.describe "config/recurring.yml" do
  let(:config) { YAML.safe_load_file(Rails.root.join("config/recurring.yml")) }

  it "registers daily_reset under production with class DailyResetJob" do
    entry = config.dig("production", "daily_reset")
    expect(entry).to be_a(Hash), "Expected production.daily_reset to be defined"
    expect(entry["class"]).to eq("DailyResetJob")
  end

  it "schedules daily_reset at midnight" do
    expect(config.dig("production", "daily_reset", "schedule")).to eq("0 0 * * *")
  end
end
