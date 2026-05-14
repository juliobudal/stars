require "rails_helper"

RSpec.describe Tasks::UpcomingService do
  include ActiveSupport::Testing::TimeHelpers

  let(:family) { create(:family, timezone: "America/Sao_Paulo") }
  let(:kid)    { create(:profile, :child, family: family) }

  describe "#call" do
    # Reference moment: 2026-05-14 (Thursday, wday 4) in São Paulo
    around { |ex| travel_to(Time.zone.local(2026, 5, 14, 12, 0, 0)) { ex.run } }

    it "returns empty when the family has no weekly/monthly tasks" do
      create(:global_task, :daily, family: family) # daily is excluded
      result = described_class.call(profile: kid)
      expect(result.success?).to be true
      expect(result.data).to eq([])
    end

    it "lists weekly tasks falling within the next 7 days" do
      friday_task = create(:global_task, :weekly, family: family, days_of_week: [ "5" ], title: "Limpar quarto")

      result = described_class.call(profile: kid)
      entries = result.data
      expect(entries.size).to eq(1)
      expect(entries.first[:global_task]).to eq(friday_task)
      expect(entries.first[:date]).to eq(Date.new(2026, 5, 15)) # next Friday
    end

    it "lists monthly tasks when day_of_month falls within the window" do
      monthly_task = create(:global_task, family: family, frequency: :monthly, day_of_month: 16, title: "Arrumar gaveta")

      result = described_class.call(profile: kid)
      expect(result.data.map { |e| e[:global_task] }).to include(monthly_task)
      expect(result.data.first[:date]).to eq(Date.new(2026, 5, 16))
    end

    it "excludes daily and once tasks" do
      create(:global_task, :daily, family: family)
      create(:global_task, family: family, frequency: :once)

      expect(described_class.call(profile: kid).data).to eq([])
    end

    it "excludes inactive tasks" do
      create(:global_task, :weekly, family: family, days_of_week: [ "5" ], active: false)

      expect(described_class.call(profile: kid).data).to eq([])
    end

    it "honors assigned_profiles when set" do
      sibling = create(:profile, :child, family: family)
      task = create(:global_task, :weekly, family: family, days_of_week: [ "5" ])
      GlobalTaskAssignment.create!(global_task: task, profile: sibling)

      expect(described_class.call(profile: kid).data).to eq([])
      expect(described_class.call(profile: sibling).data.size).to eq(1)
    end

    it "orders entries by date ascending and caps at MAX_ITEMS" do
      # 10 weekly tasks all hitting Monday — only the first MAX_ITEMS show
      10.times do |i|
        create(:global_task, :weekly, family: family, days_of_week: [ "1" ], title: "Tarefa #{i}")
      end

      result = described_class.call(profile: kid).data
      expect(result.size).to eq(Tasks::UpcomingService::MAX_ITEMS)
      dates = result.map { |e| e[:date] }
      expect(dates).to eq(dates.sort)
    end

    it "does not list today, only future days within the window" do
      # Today is Thursday 2026-05-14 (wday 4); next match is 2026-05-21
      create(:global_task, :weekly, family: family, days_of_week: [ "4" ])
      dates = described_class.call(profile: kid).data.map { |e| e[:date] }
      expect(dates).not_to include(Date.new(2026, 5, 14))
      expect(dates).to include(Date.new(2026, 5, 21))
    end
  end
end
